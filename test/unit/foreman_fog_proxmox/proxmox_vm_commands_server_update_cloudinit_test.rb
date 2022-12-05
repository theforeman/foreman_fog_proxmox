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
  class ProxmoxVmCommandsServerUpdateCloudinitTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxVmHelper

    describe 'save_vm' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'saves modified server config with added cloudinit' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('ide0')
        disks.stubs(:get).returns
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:identity).returns(uuid)
        vm.stubs(:attributes).returns('' => '')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('proxmox')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'node_id' => 'proxmox',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1',
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'ide2',
              '_delete' => '',
              'device' => '0',
              'controller' => 'ide',
              'storage_type' => 'cloud_init',
              'storage' => 'local-lvm',
              'volid' => 'local-lvm:cloudinit',
            },
          },
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'proxmox', 'type' => 'qemu', 'cores' => '1',
          'cpulimit' => '1', 'onboot' => '0')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = { id: 'ide0', storage: 'local:lvm', volid: 'local-lvm:cloudinit', media: 'cdrom' }
        vm.expects(:attach, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified server config with removed cloudinit' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns('1')
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:volid).returns('local-lvm:vm-100-cloudinit')
        disk.stubs(:media).returns('cdrom')
        disk.stubs(:id).returns('ide0')
        disk.stubs(:hard_disk?).returns(false)
        disk.stubs(:cdrom?).returns(false)
        disk.stubs(:cloud_init?).returns(true)
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '1')
        vm = mock('vm')
        vm.stubs(:identity).returns(uuid)
        vm.stubs(:attributes).returns('ide0' => '')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:templated?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('proxmox')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'node_id' => 'proxmox',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1',
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'ide0',
              '_delete' => '1',
              'device' => '0',
              'controller' => 'ide',
              'storage_type' => 'cloud_init',
              'volid' => 'local-lvm:vm-100-cloudinit',
            },
          },
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'proxmox', 'type' => 'qemu', 'cores' => '1',
          'cpulimit' => '1', 'config_attributes' => { 'onboot' => '0' })
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = 'ide0'
        vm.expects(:detach, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end
    end
  end
end
