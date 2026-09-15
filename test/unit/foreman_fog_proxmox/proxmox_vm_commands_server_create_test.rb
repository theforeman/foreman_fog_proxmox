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
require 'tempfile'

module ForemanFogProxmox
  class ProxmoxVMCommandsServerCreateTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxVMHelper

    describe 'create_vm' do
      it 'uses next vmid when requested vmid is occupied or out of range' do
        args = { vmid: '100', type: 'qemu', node_id: 'proxmox', start_after_create: '0' }
        servers = mock('servers')
        servers.expects(:id_valid?).with(100).returns(false)
        servers.expects(:next_id).returns('101')
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:parse_typed_vm).with(args, 'qemu').returns(args)
        cr.stubs(:update_boot_order).returns(nil)
        vm = mock('vm')
        servers.expects(:create).with(args).returns(vm)
        cr.create_vm(args)

        assert_equal '101', args[:vmid]
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

      it 'updates the boot order after creating a network-provisioned server' do
        args = { vmid: '100', type: 'qemu', node_id: 'proxmox', start_after_create: '0' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        vm = mock('vm')
        servers.expects(:create).with(args).returns(vm)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:parse_typed_vm).with(args, 'qemu').returns(args)
        cr.expects(:update_boot_order).with(vm, exclude_cdrom: true, include_network: true).returns(boot: 'order=net0;scsi0;virtio1')
        vm.expects(:update).with({ boot: 'order=net0;scsi0;virtio1' })

        cr.create_vm(args)
      end

      it 'creates server with bootstart' do
        args = { vmid: '100', type: 'qemu', node_id: 'proxmox', start_after_create: '1' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:parse_typed_vm).with(args, 'qemu').returns(args)
        cr.stubs(:update_boot_order).returns(nil)
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
        cr.stubs(:update_boot_order).returns(nil)
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
        image = mock('image', config: mock('config', disks: []))
        cr.stubs(:find_vm_by_uuid).with('999').returns(image)
        cr.expects(:clone_from_image).with(image, 100).returns(vm)
        vm.expects(:container?).returns(false)
        expected_args = { :vmid => "100", :type => "qemu", :name => "name" }
        cr.stubs(:parse_typed_vm).with(args, 'qemu').returns(expected_args)
        vm.expects(:update).with(expected_args)
        cr.create_vm(args)
      end

      it 'updates the boot order when cloning without user data' do
        args = { vmid: '100', type: 'qemu', image_id: '999', name: 'name', config_attributes: { onboot: '0' } }
        servers = mock('servers')
        containers = mock('containers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, containers)
        image = mock('image', config: mock('config', disks: []))
        vm = mock('vm')
        cr.expects(:clone_from_image).with(image, 100).returns(vm)
        vm.expects(:container?).returns(false)
        cr.expects(:parse_cloudinit_config).never
        cr.expects(:find_vm_by_uuid).with('999').once.returns(image)
        cr.expects(:update_boot_order).with(image).returns(boot: 'order=scsi0;virtio1')
        expected_args = { vmid: '100', type: 'qemu', name: 'name', config_attributes: { onboot: '0', boot: 'order=scsi0;virtio1' } }
        cr.expects(:parse_typed_vm).with(args, 'qemu').returns(expected_args)
        vm.expects(:update).with(expected_args)

        cr.create_vm(args)
      end

      it 'uses the cloned VM node for cloud-init ISO storage' do
        args = {
          vmid: '100',
          type: 'qemu',
          image_id: '999',
          name: 'name',
          node_id: 'selected-node',
          user_data: '#cloud-config',
        }
        servers = mock('servers')
        containers = mock('containers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, containers)
        image = mock('image', config: mock('config', disks: []))
        vm = mock('vm', node_id: 'template-node')
        cloudinit_args = args.merge(vmid: 100)

        cr.stubs(:find_vm_by_uuid).with('999').returns(image)
        cr.expects(:clone_from_image).with(image, 100).returns(vm)
        cr.expects(:parse_cloudinit_config).with(cloudinit_args, vm_node: 'template-node').returns(cloudinit_args)
        cr.stubs(:parse_typed_vm).with(cloudinit_args, 'qemu').returns(cloudinit_args)
        cr.stubs(:update_boot_order).with(image).returns({})
        vm.expects(:container?).returns(false)
        vm.expects(:update).with(cloudinit_args)

        cr.create_vm(args)
      end

      it 'attaches generated cloud-init ISO from a later ISO storage' do
        cr = ForemanFogProxmox::Proxmox.new
        client = mock('client')
        nodes = mock('nodes')
        node = mock('node')
        storages = mock('storages')
        storage = mock('storage')
        volumes = mock('volumes')
        volume = mock('volume')
        similarly_named_volume = mock('similarly_named_volume')

        volume.stubs(:volid).returns('local:iso/name_cloudinit.iso')
        similarly_named_volume.stubs(:volid).returns('local:iso/my_name_cloudinit.iso')
        volumes.stubs(:all).returns([similarly_named_volume, volume])
        storage.stubs(:volumes).returns(volumes)
        storages.stubs(:get).with('local').returns(storage)
        node.stubs(:storages).returns(storages)
        nodes.stubs(:get).with('proxmox').returns(node)
        client.stubs(:nodes).returns(nodes)
        cr.stubs(:client).returns(client)

        assert_equal({ ide2: 'local:iso/name_cloudinit.iso,media=cdrom' },
          cr.attach_cloudinit_iso('proxmox', 'local', '/tmp/name_cloudinit.iso'))
      end

      it 'uploads a generated cloud-init ISO to the selected storage' do
        cr = ForemanFogProxmox::Proxmox.new
        remote_storage = mock('remote_storage')
        local_storage = mock('local_storage')
        remote_storage.stubs(:identity).returns('remote')
        local_storage.stubs(:identity).returns('local')
        cr.stubs(:storages).with('proxmox', 'iso').returns([remote_storage, local_storage])
        Tempfile.create(['cloudinit', '.iso']) do |iso|
          remote_storage.expects(:upload_iso).with(iso.path).returns('UPID:successful-upload')
          assert_equal 'remote', cr.upload_iso('proxmox', 'remote', iso.path)
        end
      end

      it 'raises Foreman::Exception when the selected ISO upload storage is unavailable' do
        cr = ForemanFogProxmox::Proxmox.new
        local_storage = mock('local_storage', identity: 'local')
        cr.stubs(:storages).with('proxmox', 'iso').returns([local_storage])

        err = assert_raises Foreman::Exception do
          cr.upload_iso('proxmox', 'remote', '/tmp/name_cloudinit.iso')
        end

        assert_equal 'Could not find selected ISO upload storage remote for node proxmox', err.bare_message
      end

      it 'raises Foreman::Exception when no ISO upload storage is selected' do
        cr = ForemanFogProxmox::Proxmox.new
        cr.expects(:storages).never

        err = assert_raises Foreman::Exception do
          cr.upload_iso('proxmox', nil, '/tmp/name_cloudinit.iso')
        end

        assert_equal 'ISO upload storage must be selected', err.bare_message
      end

      it 'uses ISO storage on the cloned VM node when the selected node differs' do
        cr = ForemanFogProxmox::Proxmox.new
        selected_storage = mock('selected_storage', identity: 'shared-iso')
        vm_storage = mock('vm_storage')
        vm_storage.stubs(:identity).returns('shared-iso')
        cr.stubs(:storages).with('selected-node', 'iso').returns([selected_storage])
        cr.stubs(:storages).with('vm-node', 'iso').returns([vm_storage])
        selected_storage.expects(:upload_iso).never
        vm_storage.expects(:upload_iso).with('/tmp/name_cloudinit.iso').returns('UPID:successful-upload')

        assert_equal 'shared-iso', cr.upload_iso(
          'selected-node', 'shared-iso', '/tmp/name_cloudinit.iso', vm_node: 'vm-node'
        )
      end

      it 'rejects ISO storage unavailable on the cloned VM node' do
        cr = ForemanFogProxmox::Proxmox.new
        selected_storage = mock('selected_storage', identity: 'local')
        cr.stubs(:storages).with('selected-node', 'iso').returns([selected_storage])
        cr.stubs(:storages).with('vm-node', 'iso').returns([])

        err = assert_raises Foreman::Exception do
          cr.upload_iso('selected-node', 'local', '/tmp/name_cloudinit.iso', vm_node: 'vm-node')
        end

        assert_equal 'Selected ISO upload storage local is not accessible from cloned VM node vm-node', err.bare_message
      end

      it 'raises Foreman::Exception when generated cloud-init ISO is not on any ISO storage' do
        cr = ForemanFogProxmox::Proxmox.new
        client = mock('client')
        nodes = mock('nodes')
        node = mock('node')
        storages = mock('storages')
        storage = mock('storage')
        volumes = mock('volumes')
        other_volume = mock('other_volume')

        other_volume.stubs(:volid).returns('local:iso/other.iso')
        volumes.stubs(:all).returns([other_volume])
        storage.stubs(:volumes).returns(volumes)
        storages.stubs(:get).with('local').returns(storage)
        node.stubs(:storages).returns(storages)
        nodes.stubs(:get).with('proxmox').returns(node)
        client.stubs(:nodes).returns(nodes)
        cr.stubs(:client).returns(client)

        err = assert_raises Foreman::Exception do
          cr.attach_cloudinit_iso('proxmox', 'local', '/tmp/name_cloudinit.iso')
        end

        assert err.message.end_with?('Could not find generated cloud-init ISO name_cloudinit.iso on storage local for node proxmox')
      end
    end

    describe 'validate_image_template_disk_slots!' do
      it 'moves a disk that conflicts with an image template disk to the next free slot' do
        cr = ForemanFogProxmox::Proxmox.new
        disk = mock('disk', hard_disk?: true, id: 'scsi0')
        image = mock('image', config: mock('config', disks: [disk]))
        args = {
          'volumes_attributes' => {
            '0' => { 'storage_type' => 'hard_disk', 'controller' => 'scsi', 'device' => '0', 'id' => 'scsi0' },
          },
        }
        cr.validate_image_template_disk_slots!(image, args)

        assert_equal '1', args['volumes_attributes']['0']['device']
        assert_equal 'scsi1', args['volumes_attributes']['0']['id']
      end

      it 'uses a free slot before the conflicting slot' do
        cr = ForemanFogProxmox::Proxmox.new
        disk = mock('disk', hard_disk?: true, id: 'scsi1')
        image = mock('image', config: mock('config', disks: [disk]))
        args = {
          'volumes_attributes' => {
            '0' => { 'storage_type' => 'hard_disk', 'controller' => 'scsi', 'device' => '1', 'id' => 'scsi1' },
          },
        }
        cr.validate_image_template_disk_slots!(image, args)

        assert_equal '0', args['volumes_attributes']['0']['device']
        assert_equal 'scsi0', args['volumes_attributes']['0']['id']
      end

      it 'leaves a disk unchanged when its slot does not conflict with an image template disk' do
        cr = ForemanFogProxmox::Proxmox.new
        disk = mock('disk', hard_disk?: true, id: 'scsi0')
        image = mock('image', config: mock('config', disks: [disk]))
        args = {
          'volumes_attributes' => {
            '0' => { 'storage_type' => 'hard_disk', 'controller' => 'scsi', 'device' => '1', 'id' => 'scsi1' },
          },
        }
        original_args = args.deep_dup
        cr.validate_image_template_disk_slots!(image, args)

        assert_equal original_args, args
      end

      it 'raises when no free disk slot is available for the controller' do
        cr = ForemanFogProxmox::Proxmox.new
        disks = (0..3).map { |device| mock("disk#{device}", hard_disk?: true, id: "ide#{device}") }
        image = mock('image', config: mock('config', disks: disks))
        args = {
          'volumes_attributes' => {
            '0' => { 'storage_type' => 'hard_disk', 'controller' => 'ide', 'device' => '3', 'id' => 'ide3' },
          },
        }
        error = assert_raises Foreman::Exception do
          cr.validate_image_template_disk_slots!(image, args)
        end

        assert_equal 'No free disk device is available for the ide controller.', error.bare_message
      end
    end
  end
end
