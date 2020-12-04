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

      it 'migrates server from node to another one in the cluster' do
        uuid = '100'
        config = mock('config')
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:templated?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('proxmox')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        attr = { 'templated' => '0', 'node_id' => 'proxmox2' }
        vm.expects(:migrate)
        @cr.save_vm(uuid, attr)
      end

      it 'saves modified server config with same volumes' do
        uuid = '100'
        config = mock('config')
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:templated?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('proxmox')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        attr = { 'templated' => '0', 'node_id' => 'proxmox', 'config_attributes' => { 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' } }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'proxmox', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0')
        expected_attr = { :cores => '1', :cpulimit => '1' }.with_indifferent_access
        vm.expects(:update, expected_attr)
        @cr.save_vm(uuid, attr)
      end

      it 'saves server as template' do
        uuid = '100'
        config = mock('config')
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:templated?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        attr = { 'templated' => '1' }
        vm.expects(:create_template)
        @cr.save_vm(uuid, attr)
      end

      it 'saves modified server config with removed interfaces' do
        uuid = '100'
        config = mock('config')
        interfaces = mock('interfaces')
        interface = mock('interface')
        interface.stubs(:id).returns('net0')
        interfaces.stubs(:get).returns(interface)
        config.stubs(:interfaces).returns(interfaces)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
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
            'cpulimit' => '1'
          },
          'interfaces_attributes' => {
            '0' => {
              '_delete' => '1',
              'id' => 'net0'
            }
          }
        }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns(
          'vmid' => '100',
          'node_id' => 'proxmox',
          'type' => 'qemu',
          'cores' => '1',
          'cpulimit' => '1',
          'delete' => 'net0',
          'onboot' => '0'
        )
        expected_config_attr = { :cores => '1', :cpulimit => '1', :delete => 'net0' }
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves server config with modified pool' do
        uuid = '100'
        config = mock('config')
        config.stubs(:pool).returns('pool1')
        config.expects(:pool=).with('pool1')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('proxmox')
        vm.stubs(:vmid).returns(uuid)
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        identity_client = mock('identity_client')
        pools = mock('pools')
        pool1 = mock('pool1')
        pool1.stubs(:poolid).returns('pool1')
        pool1.stubs(:has_server?).with('100').returns(true)
        pool1.expects(:remove_server).with(uuid)
        pool2 = mock('pool2')
        pool2.stubs(:poolid).returns('pool2')
        pool2.stubs(:has_server?).with('100').returns(false)
        pool2.expects(:add_server).with(uuid)
        pools.stubs(:all).returns([pool1, pool2])
        pools.expects(:get).with('pool1').returns(pool1)
        pools.expects(:get).with('pool2').returns(pool2)
        identity_client.stubs(:pools).returns(pools)
        @cr.stubs(:identity_client).returns(identity_client)
        attr = { 'templated' => '0', 'node_id' => 'proxmox', 'pool' => 'pool2', 'config_attributes' => { 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' } }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'proxmox', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0', 'pool' => 'pool2')
        vm.expects(:update).with({ 'node_id' => 'proxmox', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' }.with_indifferent_access)
        @cr.save_vm(uuid, attr)
      end

      it 'saves server config with removed pool' do
        uuid = '100'
        config = mock('config')
        config.expects(:pool=).with('pool1')
        config.stubs(:pool).returns('pool1')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('proxmox')
        vm.stubs(:vmid).returns(uuid)
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        identity_client = mock('identity_client')
        pools = mock('pools')
        pool1 = mock('pool1')
        pool1.stubs(:has_server?).with('100').returns(true)
        pool1.stubs(:poolid).returns('pool1')
        pool1.expects(:remove_server).with(uuid)
        pools.stubs(:all).returns([pool1])
        pools.expects(:get).with('pool1').returns(pool1)
        pools.expects(:get).with('').returns(nil)
        identity_client.stubs(:pools).returns(pools)
        @cr.stubs(:identity_client).returns(identity_client)
        attr = { 'templated' => '0', 'node_id' => 'proxmox', 'pool' => '', 'config_attributes' => { 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' } }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'proxmox', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0', 'pool' => '')
        vm.expects(:update).with({ 'node_id' => 'proxmox', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' }.with_indifferent_access)
        @cr.save_vm(uuid, attr)
      end

      it 'saves server config with added pool' do
        uuid = '100'
        config = mock('config')
        config.expects(:pool=).with(nil)
        config.stubs(:pool).returns(nil)
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('proxmox')
        vm.stubs(:vmid).returns(uuid)
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        identity_client = mock('identity_client')
        pools = mock('pools')
        pool2 = mock('pool2')
        pool2.stubs(:has_server?).with('100').returns(false)
        pool2.stubs(:poolid).returns('pool2')
        pool2.expects(:add_server).with(uuid)
        pools.stubs(:all).returns([pool2])
        pools.expects(:get).with('pool2').returns(pool2)
        pools.expects(:get).with('').returns(nil)
        identity_client.stubs(:pools).returns(pools)
        @cr.stubs(:identity_client).returns(identity_client)
        attr = { 'templated' => '0', 'node_id' => 'proxmox', 'pool' => 'pool2', 'config_attributes' => { 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' } }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'node_id' => 'proxmox', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0', 'pool' => 'pool2')
        vm.expects(:update).with({ 'node_id' => 'proxmox', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' }.with_indifferent_access)
        @cr.save_vm(uuid, attr)
      end
    end
  end
end
