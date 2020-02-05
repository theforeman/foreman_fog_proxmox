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
  class ProxmoxVmCommandsServerUpdateTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxVmHelper

    describe 'save_vm' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'saves modified server config with added volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('scsi0')
        disks.stubs(:get).returns
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('pve')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'node_id' => 'pve',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'scsi0',
              '_delete' => '',
              'device' => '0',
              'controller' => 'scsi',
              'storage' => 'local-lvm',
              'size' => '2147483648',
              'cache' => 'none'
            }
          }
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'pve', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = { id: 'scsi0', storage: 'local:lvm', size: (2_147_483_648 / GIGA).to_s }
        vm.expects(:attach, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified server config with removed volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('virtio0')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:templated?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('pve')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'node_id' => 'pve',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              '_delete' => '1',
              'id' => 'scsi0',
              'volid' => 'local-lvm:vm-100-disk-0',
              'device' => '0',
              'controller' => 'scsi',
              'storage' => 'local-lvm',
              'size' => '2147483648',
              'cache' => 'none'
            }
          }
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'pve', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'config_attributes' => { 'onboot' => '0' })
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = 'scsi0'
        vm.expects(:detach, expected_volume_attr)
        vm.expects(:detach, 'unused0')
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified server config with resized volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:templated?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('pve')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'node_id' => 'pve',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'scsi0',
              '_delete' => '',
              'volid' => 'local-lvm:vm-100-disk-0',
              'device' => '0',
              'controller' => 'scsi',
              'storage' => 'local-lvm',
              'size' => '2147483648',
              'cache' => 'none'
            }
          }
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'pve', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = ['scsi0', '+1G']
        vm.expects(:extend, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'raises error unable to shrink volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('pve')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'node_id' => 'pve',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'scsi0',
              '_delete' => '',
              'volid' => 'local-lvm:vm-100-disk-0',
              'device' => '0',
              'controller' => 'scsi',
              'storage' => 'local-lvm',
              'size' => '2',
              'cache' => 'none'
            }
          }
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'pve', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        err = assert_raises Foreman::Exception do
          @cr.save_vm(uuid, new_attributes)
        end
        assert err.message.end_with?('Unable to shrink scsi0 size. Proxmox allows only increasing size.')
      end

      it 'saves modified server config with moved volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('pve')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'node_id' => 'pve',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'scsi0',
              '_delete' => '',
              'volid' => 'local-lvm:vm-100-disk-0',
              'device' => '0',
              'controller' => 'scsi',
              'storage' => 'local-lvm2',
              'size' => '1073741824',
              'cache' => 'none'
            }
          }
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'pve', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = ['scsi0', 'local-lvm2']
        vm.expects(:move, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified server config with modified volumes options' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:volid).returns('local-lvm:vm-100-disk-0')
        disk.stubs(:id).returns('scsi0')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('pve')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'node_id' => 'pve',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'scsi0',
              '_delete' => '',
              'volid' => 'local-lvm:vm-100-disk-0',
              'device' => '0',
              'controller' => 'scsi',
              'storage' => 'local-lvm',
              'size' => '1073741824',
              'cache' => 'directsync'
            }
          }
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'pve', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = { :id => 'scsi0', :volid => 'local-lvm:vm-100-disk-0', :size => 1_073_741_824 }, { :cache => 'directsync' }
        vm.expects(:attach, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end
    end
  end
end
