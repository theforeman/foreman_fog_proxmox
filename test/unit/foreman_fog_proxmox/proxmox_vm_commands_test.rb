# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

require 'test_plugin_helper'
require 'models/compute_resources/compute_resource_test_helpers'
require 'factories/foreman_fog_proxmox/proxmox_node_mock_factory'
require 'factories/foreman_fog_proxmox/proxmox_server_mock_factory'
require 'factories/foreman_fog_proxmox/proxmox_container_mock_factory'
require 'active_support/core_ext/hash/indifferent_access'

module ForemanFogProxmox
  class ProxmoxVMCommandsServerTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVMHelper

    describe 'destroy_vm' do
      it 'handles situation when vm is not present' do
        cr = mock_cr_servers(ForemanFogProxmox::Proxmox.new, empty_servers)
        cr.expects(:find_vm_by_uuid).raises(ActiveRecord::RecordNotFound)
        assert cr.destroy_vm('abc')
      end

      it 'succeeds when lookup confirms that the VM is absent' do
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, empty_servers, empty_servers)

        assert cr.destroy_vm('1_100')
      end

      it 'does not report success when the VM could be on an offline node' do
        cr = ForemanFogProxmox::Proxmox.new
        offline = mock('offline', node: 'node-a', status: 'offline')
        offline.expects(:servers).never
        offline.expects(:containers).never
        cr.expects(:nodes).once.returns([offline])

        assert_raises(::Foreman::Exception) { cr.destroy_vm('1_100') }
      end

      it 'does not report success when the lookup API fails' do
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new,
          servers_raising_exception(Fog::Errors::Error.new('API unavailable')))

        assert_raises(::Foreman::Exception) { cr.destroy_vm('1_100') }
      end

      [true, false].product([0, 1]).each do |running, managed|
        it "deletes a #{running ? 'running' : 'stopped'} VM with HA managed=#{managed}" do
          cr = ForemanFogProxmox::Proxmox.new
          vm = mock('vm', ready?: running, ha: { 'managed' => managed })
          cr.expects(:find_vm_by_uuid).with('1_100').returns(vm)
          running ? vm.expects(:stop) : vm.expects(:stop).never
          if managed == 1
            vm.expects(:destroy).with(query: { purge: 1 }).returns(true)
          else
            vm.expects(:destroy).with.returns(true)
          end

          assert cr.destroy_vm('1_100')
        end
      end
    end

    describe 'create_vm' do
      %w[qemu lxc].product([0, 1]).each do |type, managed|
        it "cleans up a created #{type} VM with HA managed=#{managed} without rediscovering its offline node" do
          args = { vmid: '100', type: type, node_id: 'offline', start_after_create: '1' }
          servers = mock('servers')
          containers = mock('containers')
          servers.expects(:id_valid?).with(100).returns(true)
          cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, containers)
          node = cr.send(:client).nodes.get('offline')
          node.stubs(:node).returns('offline')
          node.stubs(:status).returns('offline')
          cr.expects(:find_vm_by_uuid).never
          cr.expects(:available_nodes).never
          cr.stubs(:parse_typed_vm).with(args, type).returns(args)
          cr.stubs(:update_boot_order).returns(nil)
          vm = mock('vm', ready?: true, ha: { 'managed' => managed })
          node.public_send(vm_collection(type)).expects(:create).with(args).returns(vm)
          failure = RuntimeError.new('start failed')
          vm.expects(:start).raises(failure)
          vm.expects(:reload).returns(vm)
          vm.expects(:stop)
          if managed == 1
            vm.expects(:destroy).with(query: { purge: 1 }).returns(true)
          else
            vm.expects(:destroy).with.returns(true)
          end

          assert_same failure, assert_raises(RuntimeError) { cr.create_vm(args) }
        end
      end

      %w[qemu lxc].each do |type|
        it "cleans up the new #{type} clone, not its template, when configuration fails" do
          args = { vmid: '100', type: type, node_id: 'offline', image_id: '1_999' }
          servers = stub(id_valid?: true)
          cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, stub)
          node = cr.send(:client).nodes.get('offline')
          node.stubs(:status).returns('offline')
          cr.expects(:available_nodes).never
          image = mock('image')
          image.expects(:destroy).never
          cr.expects(:find_vm_by_uuid).with('1_999').once.returns(image)
          cr.stubs(:validate_image_template_disk_slots!)
          vm = mock('vm', container?: type == 'lxc', ready?: false, ha: nil)
          cr.expects(:clone_from_image).with(image, 100).returns(vm)
          cr.stubs(:compute_clone_attributes).returns({})
          failure = RuntimeError.new('configuration failed')
          vm.expects(:update).with({}).raises(failure)
          vm.expects(:reload).returns(vm)
          vm.expects(:stop).never
          vm.expects(:destroy).with.returns(true)

          assert_same failure, assert_raises(RuntimeError) { cr.create_vm(args) }
        end
      end
    end

    describe 'rollback_vm_instance' do
      %w[qemu lxc].each do |type|
        it "stops a real Fog #{type} VM after start succeeds but its status reload fails" do
          cr = ForemanFogProxmox::Proxmox.new
          service = stub(list_tasks: [])
          collection = Fog::Proxmox::Compute::Servers.new(service: service, node_id: 'node-a', type: type)
          vm = collection.new(vmid: 100, status: 'stopped', ha: { 'managed' => 0 })
          running = collection.new(vmid: 100, status: 'running', ha: { 'managed' => 0 })
          stopped = collection.new(vmid: 100, status: 'stopped', ha: { 'managed' => 0 })
          failure = Fog::Errors::Error.new('status unavailable after successful start')
          collection.expects(:get).with(100).times(3).raises(failure).then.returns(running, stopped)
          order = sequence('VM requests')
          vm.expects(:request).with(:action_server, {}, action: 'start', vmid: 100).returns(true).in_sequence(order)
          vm.expects(:request).with(:action_server, {}, action: 'stop', vmid: 100).returns(true).in_sequence(order)
          vm.expects(:request).with(:delete_server, {}, { vmid: 100 }, nil).returns(true).in_sequence(order)
          cr.expects(:find_vm_by_uuid).never

          assert_same failure, assert_raises(Fog::Errors::Error) { vm.start }
          assert_not vm.ready?
          assert cr.send(:rollback_vm_instance, vm)
        end
      end

      it 'refreshes power and HA state before deciding how to delete' do
        cr = ForemanFogProxmox::Proxmox.new
        vm = mock('vm')
        order = sequence('rollback')
        vm.expects(:reload).returns(vm).in_sequence(order)
        vm.expects(:ready?).returns(true).in_sequence(order)
        vm.expects(:stop).in_sequence(order)
        vm.expects(:ha).returns('managed' => 1).in_sequence(order)
        vm.expects(:destroy).with(query: { purge: 1 }).returns(true).in_sequence(order)

        assert cr.send(:rollback_vm_instance, vm)
      end

      [nil, Fog::Errors::Error.new('refresh failed')].each do |result|
        it "reports cleanup failure without using cached state when refresh #{result ? 'raises' : 'returns nil'}" do
          cr = ForemanFogProxmox::Proxmox.new
          vm = stub(vmid: 100, node_id: 'node-a')
          reload = vm.expects(:reload)
          result ? reload.raises(result) : reload.returns(nil)
          vm.expects(:ready?).never
          vm.expects(:destroy).never
          cr.logger.expects(:error).with(regexp_matches(/Failed to clean up Proxmox VM 100 on node node-a/))

          error = assert_raises(result ? Fog::Errors::Error : ::Foreman::Exception) { cr.send(:rollback_vm_instance, vm) }
          assert_same result, error if result
        end
      end
    end

    describe 'assign_vmid' do
      it 'uses next vmid when requested vmid is already occupied' do
        cr = ForemanFogProxmox::Proxmox.new
        servers = mock('servers')
        node = mock('node')
        node.stubs(:servers).returns(servers)
        servers.expects(:id_valid?).with(100).returns(false)
        servers.expects(:next_id).returns('101')

        assert_equal '101', cr.assign_vmid(100, node)
      end

      it 'does not log when logging is disabled' do
        cr = ForemanFogProxmox::Proxmox.new
        servers = mock('servers')
        node = mock('node')
        node.stubs(:servers).returns(servers)
        servers.expects(:id_valid?).with(100).returns(false)
        servers.expects(:next_id).returns('101')
        cr.logger.expects(:warn).never

        assert_equal '101', cr.assign_vmid(100, node, log: false)
      end
    end
  end
end
