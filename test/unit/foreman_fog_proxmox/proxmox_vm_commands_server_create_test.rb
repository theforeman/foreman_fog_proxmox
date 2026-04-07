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

      it 'applies boot order when cloning without user_data' do
        args = { vmid: '100', type: 'qemu', image_id: '999', name: 'name', config_attributes: { onboot: '0' } }
        servers = mock('servers')
        containers = mock('containers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, containers)
        vm = mock('vm')
        cr.expects(:clone_from_image).with('999', 100).returns(vm)
        vm.expects(:container?).returns(false)
        cr.expects(:parse_cloudinit_config).never
        cr.expects(:update_boot_order).with('999').returns(boot: 'order=scsi0;virtio1')

        expected_args = { vmid: '100', type: 'qemu', name: 'name', config_attributes: { onboot: '0', boot: 'order=scsi0;virtio1' } }

        cr.expects(:parse_typed_vm).with do |parsed_args, parsed_type|
          assert_equal 'qemu', parsed_type
          assert_equal expected_args[:config_attributes], parsed_args[:config_attributes]
          true
        end.returns(expected_args)

        vm.expects(:update).with(expected_args)
        cr.create_vm(args)
      end

      it 'attaches generated cloud-init ISO from a later ISO storage' do
        cr = ForemanFogProxmox::Proxmox.new
        first_storage = mock('first_storage')
        second_storage = mock('second_storage')
        volume = mock('volume')

        first_storage.stubs(:volumes).returns([])
        volume.stubs(:volid).returns('local:iso/name_cloudinit.iso')
        second_storage.stubs(:volumes).returns([volume])
        cr.stubs(:storages).with('proxmox', 'iso').returns([first_storage, second_storage])

        assert_equal({ ide2: 'local:iso/name_cloudinit.iso,media=cdrom' },
          cr.attach_cloudinit_iso('proxmox', '/var/lib/vz/template/iso/name_cloudinit.iso'))
      end

      it 'raises Foreman::Exception when generated cloud-init ISO is not on any ISO storage' do
        cr = ForemanFogProxmox::Proxmox.new
        storage = mock('storage')
        other_volume = mock('other_volume')

        other_volume.stubs(:volid).returns('local:iso/other.iso')
        storage.stubs(:volumes).returns([other_volume])
        cr.stubs(:storages).with('proxmox', 'iso').returns([storage])

        err = assert_raises Foreman::Exception do
          cr.attach_cloudinit_iso('proxmox', '/var/lib/vz/template/iso/name_cloudinit.iso')
        end

        assert err.message.end_with?('Could not find generated cloud-init ISO name_cloudinit.iso on any ISO storage for node proxmox')
      end
    end
  end
end
