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
require 'active_support/core_ext/hash/indifferent_access'

module ForemanFogProxmox
  class ProxmoxVMCommandsServerCreateTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxVMHelper

    describe 'create_vm' do
      it 'raises Foreman::Exception when vmid <= 100 and vmid > 0' do
        args = { vmid: '100' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(false)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        err = assert_raises Foreman::Exception do
          cr.create_vm(args)
        end
        assert err.message.end_with?('invalid vmid=100')
      end

      it 'computes next vmid when vmid == 0 and creates server' do
        args = { vmid: '0', type: 'qemu', node_id: 'proxmox', start_after_create: '0' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        servers.stubs(:next_id).returns('101')
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:parse_typed_vm).with(args, 'qemu').returns(args)
        servers.stubs(:create).with(args)
        vm = mock('vm')
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.create_vm(args)
      end

      it 'creates server without bootstart' do
        args = { vmid: '100', type: 'qemu', node_id: 'proxmox', start_after_create: '0' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:parse_typed_vm).with(args, 'qemu').returns(args)
        servers.stubs(:create).with(args)
        vm = mock('vm')
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.create_vm(args)
      end

      it 'creates server with bootstart' do
        args = { vmid: '100', type: 'qemu', node_id: 'proxmox', start_after_create: '1' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:parse_typed_vm).with(args, 'qemu').returns(args)
        vm = mock('vm')
        servers.stubs(:create).with(args).returns(vm)
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.stubs(:start_on_boot).with(vm, args).returns(vm)
        cr.create_vm(args)
      end

      it 'creates server within pool' do
        args = { vmid: '100', type: 'qemu', node_id: 'proxmox', start_after_create: '0', pool: 'pool1' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:parse_typed_vm).with(args, 'qemu').returns(args)
        vm = mock('vm')
        servers.stubs(:create).with(args).returns(vm)
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.stubs(:start_on_boot).with(vm, args).returns(vm)
        cr.create_vm(args)
      end

      it 'clones server' do
        args = { vmid: '100', type: 'qemu', image_id: '999', name: 'name' }
        servers = mock('servers')
        containers = mock('containers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, containers)
        vm = mock('vm')
        cr.expects(:clone_from_image).with('999', 100).returns(vm)
        vm.expects(:container?).returns(false)
        expected_args = { :vmid => "100", :type => "qemu", :name => "name" }
        cr.stubs(:parse_typed_vm).with(args, 'qemu').returns(expected_args)
        vm.expects(:update).with(expected_args)
        cr.create_vm(args)
      end

      it 'attaches generated cloud-init ISO from a later ISO storage' do
        cr = ForemanFogProxmox::Proxmox.new
        first_storage = mock('first_storage')
        second_storage = mock('second_storage')
        first_node_storage = mock('first_node_storage')
        second_node_storage = mock('second_node_storage')
        volume = mock('volume')
        client = mock('client')
        nodes = mock('nodes')
        node = mock('node')
        node_storages = mock('node_storages')

        first_storage.stubs(:storage).returns('first')
        second_storage.stubs(:storage).returns('local')
        first_node_storage.stubs(:volumes).returns([])
        volume.stubs(:volid).returns('local:iso/name_cloudinit.iso')
        second_node_storage.stubs(:volumes).returns([volume])
        node_storages.stubs(:get).with('first').returns(first_node_storage)
        node_storages.stubs(:get).with('local').returns(second_node_storage)
        node.stubs(:storages).returns(node_storages)
        nodes.stubs(:get).with('proxmox').returns(node)
        client.stubs(:nodes).returns(nodes)
        cr.stubs(:client).returns(client)
        cr.stubs(:storages).with('proxmox', 'iso').returns([first_storage, second_storage])

        assert_equal({ ide2: 'local:iso/name_cloudinit.iso,media=cdrom' },
          cr.attach_cloudinit_iso('proxmox', '/var/lib/vz/template/iso/name_cloudinit.iso'))
      end

      it 'raises Foreman::Exception when generated cloud-init ISO is not on any ISO storage' do
        cr = ForemanFogProxmox::Proxmox.new
        storage = mock('storage')
        node_storage = mock('node_storage')
        other_volume = mock('other_volume')
        client = mock('client')
        nodes = mock('nodes')
        node = mock('node')
        node_storages = mock('node_storages')

        other_volume.stubs(:volid).returns('local:iso/other.iso')
        storage.stubs(:storage).returns('local')
        node_storage.stubs(:volumes).returns([other_volume])
        node_storages.stubs(:get).with('local').returns(node_storage)
        node.stubs(:storages).returns(node_storages)
        nodes.stubs(:get).with('proxmox').returns(node)
        client.stubs(:nodes).returns(nodes)
        cr.stubs(:client).returns(client)
        cr.stubs(:storages).with('proxmox', 'iso').returns([storage])

        err = assert_raises Foreman::Exception do
          cr.attach_cloudinit_iso('proxmox', '/var/lib/vz/template/iso/name_cloudinit.iso')
        end

        assert err.message.end_with?('Could not find generated cloud-init ISO name_cloudinit.iso on any ISO storage for node proxmox')
      end
    end
  end
end
