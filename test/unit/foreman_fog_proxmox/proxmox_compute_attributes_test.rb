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
  class ProxmoxComputeAttributesTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVmHelper

    describe 'host_compute_attrs' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'raises Foreman::Exception when server ostype does not match os family' do
        operatingsystem = FactoryBot.build(:solaris)
        physical_nic = FactoryBot.build(:nic_base_empty, :identifier => 'net0', :primary => true)
        host = FactoryBot.build(
          :host_empty,
          :interfaces => [physical_nic],
          :operatingsystem => operatingsystem,
          :compute_attributes => {
            'type' => 'qemu',
            'config_attributes' => {
              'ostype' => 'l26'
            },
            'interfaces_attributes' => {
              '0' => physical_nic
            }
          }
        )
        err = assert_raises Foreman::Exception do
          @cr.host_compute_attrs(host)
        end
        assert err.message.end_with?('Operating system family Solaris is not consistent with l26')
      end

      it 'sets container hostname with host name' do
        physical_nic = FactoryBot.build(:nic_base_empty, :identifier => 'net0', :primary => true, :compute_attributes => { 'dhcp' => '1' })
        host = FactoryBot.build(
          :host_empty,
          :interfaces => [physical_nic],
          :compute_attributes => {
            'type' => 'lxc',
            'config_attributes' => {
              'hostname' => ''
            },
            'interfaces_attributes' => {
              '0' => {}
            }
          }
        )
        @cr.host_compute_attrs(host)
        assert_equal host.name, host.compute_attributes['config_attributes']['hostname']
      end
    end

    describe 'vm_compute_attributes' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'converts a server to hash' do
        vm, config_attributes, volume_attributes, interface_attributes = mock_server_vm
        vm_attrs = @cr.vm_compute_attributes(vm)
        assert_not vm_attrs.key?(:config)
        assert vm_attrs.key?(:config_attributes)
        assert_equal config_attributes.reject { |key, value| [:vmid, :disks, :interfaces].include?(key) || value.to_s.empty? }, vm_attrs[:config_attributes]
        assert_not vm_attrs[:config_attributes].key?(:disks)
        assert vm_attrs.key?(:volumes_attributes)
        assert_equal volume_attributes, vm_attrs[:volumes_attributes]['0']
        assert_not vm_attrs[:config_attributes].key?(:interfaces)
        assert vm_attrs.key?(:interfaces_attributes)
        assert_equal interface_attributes, vm_attrs[:interfaces_attributes]['0']
      end

      it 'converts a container to hash' do
        vm, config_attributes, volume_attributes, interface_attributes = mock_container_vm
        vm_attrs = @cr.vm_compute_attributes(vm)
        assert_not vm_attrs.key?(:config)
        assert vm_attrs.key?(:config_attributes)
        assert_equal config_attributes.reject { |key, value| [:vmid, :disks, :interfaces].include?(key) || value.to_s.empty? }, vm_attrs[:config_attributes]
        assert_not vm_attrs[:config_attributes].key?(:disks)
        assert vm_attrs.key?(:volumes_attributes)
        assert_equal volume_attributes, vm_attrs[:volumes_attributes]['0']
        assert vm_attrs.key?(:interfaces_attributes)
        assert_equal interface_attributes, vm_attrs[:interfaces_attributes]['0']
      end
    end
  end
end
