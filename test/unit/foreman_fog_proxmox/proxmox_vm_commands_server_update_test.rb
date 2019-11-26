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

      it 'saves modified server config with same volumes' do
        uuid = '100'
        config = mock('config')
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:templated?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        attr = { 'templated' => '0', 'config_attributes' => { 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0' } }.with_indifferent_access
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1', 'onboot' => '0')
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
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
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
    end
  end
end
