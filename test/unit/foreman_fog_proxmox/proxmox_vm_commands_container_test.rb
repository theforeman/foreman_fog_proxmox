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
require 'factories/foreman_fog_proxmox/proxmox_container_mock_factory'
require 'active_support/core_ext/hash/indifferent_access'

module ForemanFogProxmox
  class ProxmoxVmCommandsContainerTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVmHelper

    describe 'save_vm' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'migrates container from one node to another in the cluster' do
        uuid = '100'
        config = mock('config')
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(true)
        vm.stubs(:type).returns('lxc')
        vm.stubs(:node_id).returns('pve')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        attr = { 'templated' => '0', 'node_id' => 'pve', 'config_attributes' => { 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' } }.with_indifferent_access
        @cr.stubs(:parse_container_vm).returns('vmid' => '100', 'node_id' => 'pve2', 'type' => 'lxc', 'cores' => '1', 'cpulimit' => '1')
        expected_attr = { :cores => '1', :cpulimit => '1' }
        vm.expects(:update, expected_attr)
        @cr.save_vm(uuid, attr)
      end

      it 'saves modified container config' do
        uuid = '100'
        config = mock('config')
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(true)
        vm.stubs(:type).returns('lxc')
        vm.stubs(:node_id).returns('pve')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        attr = { 'templated' => '0', 'node_id' => 'pve', 'config_attributes' => { 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' } }.with_indifferent_access
        @cr.stubs(:parse_container_vm).returns('vmid' => '100', 'node_id' => 'pve', 'type' => 'lxc', 'cores' => '1', 'cpulimit' => '1')
        expected_attr = { :cores => '1', :cpulimit => '1' }
        vm.expects(:update, expected_attr)
        @cr.save_vm(uuid, attr)
      end

      it 'saves modified container config with added volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('mp0')
        disks.stubs(:get).returns
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(true)
        vm.stubs(:type).returns('lxc')
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
              'id' => 'mp0',
              '_delete' => '',
              'device' => '0',
              'storage' => 'local-lvm',
              'size' => '2147483648',
              'cache' => 'none',
              'mp' => '/opt/path'
            }
          }
        }.with_indifferent_access
        @cr.stubs(:parse_container_vm).returns('vmid' => '100', 'node_id' => 'pve', 'type' => 'lxc', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr =
          [
            {
              id: 'mp0',
              storage: 'local:lvm',
              size: (2_147_483_648 / GIGA).to_s
            },
            {
              mp: '/opt/path'
            }
          ]
        vm.expects(:attach, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified container config with resized volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('rootfs')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(true)
        vm.stubs(:type).returns('lxc')
        vm.stubs(:node_id).returns('pve')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes =
          {
            'templated' => '0',
            'node_id' => 'pve',
            'config_attributes' => {
              'cores' => '1',
              'cpulimit' => '1',
              'onboot' => '0'
            },
            'volumes_attributes' => {
              '0' => {
                'id' => 'rootfs',
                '_delete' => '',
                'volid' => 'local-lvm:1073741824',
                'device' => '0',
                'storage' => 'local-lvm',
                'size' => '2147483648',
                'cache' => 'none'
              }
            }
          }.with_indifferent_access
        @cr.stubs(:parse_container_vm).returns(
          'vmid' => '100',
          'node_id' => 'pve',
          'type' => 'lxc',
          'cores' => '1',
          'cpulimit' => '1'
        )
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = ['rootfs', '+1G']
        vm.expects(:extend, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified container config with modified volumes options' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:rootfs?).returns(false)
        disk.stubs(:volid).returns('local-lvm:vm-100-disk-0')
        disk.stubs(:id).returns('mp0')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(true)
        vm.stubs(:type).returns('lxc')
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
              'id' => 'mp0',
              '_delete' => '',
              'volid' => 'local-lvm:vm-100-disk-0',
              'device' => '0',
              'controller' => 'mp',
              'storage' => 'local-lvm',
              'size' => '1073741824',
              'mp' => '/opt/toto'
            }
          }
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'pve', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = { :id => 'mp0', :volid => 'local-lvm:vm-100-disk-0', :size => 1_073_741_824 }, { :mp => '/opt/toto' }
        vm.expects(:attach, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end
    end

    describe 'create_vm' do
      it 'creates container without bootstart' do
        args = { vmid: '100', type: 'lxc', node_id: 'pve', config_attributes: { onboot: '0' } }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        containers = mock('containers')
        containers.stubs(:create).with(vmid: 100, type: 'lxc', node_id: 'pve', config_attributes: { onboot: '0' })
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, containers)
        cr.stubs(:convert_sizes).with(args)
        cr.stubs(:parse_container_vm).with(args).returns(args)
        vm = mock('vm')
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.create_vm(args)
      end

      it 'creates container with bootstart' do
        args = { vmid: '100', type: 'lxc', node_id: 'pve', config_attributes: { onboot: '0' } }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        containers = mock('containers')
        vm = mock('vm')
        containers.stubs(:create).with(vmid: 100, type: 'lxc', node_id: 'pve', config_attributes: { onboot: '0' }).returns(vm)
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, containers)
        cr.stubs(:convert_sizes).with(args)
        cr.stubs(:parse_container_vm).with(args).returns(args)
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.stubs(:start_on_boot).with(vm, args).returns(vm)
        cr.create_vm(args)
      end

      it 'clones container' do
        args = { vmid: '100', type: 'lxc', image_id: '999', name: 'name' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.expects(:clone_from_image).with('999', args, 100)
        cr.create_vm(args)
      end
    end
  end
end
