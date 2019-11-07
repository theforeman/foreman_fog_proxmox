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
  class ProxmoxInterfacesTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVmHelper

    describe 'host_interfaces_attrs' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'raises Foreman::Exception when physical identifier does not match net[k] with k integer' do
        physical_nic = FactoryBot.build(:nic_base_empty, :identifier => 'eth0')
        host = FactoryBot.build(:host_empty, :interfaces => [physical_nic])
        err = assert_raises Foreman::Exception do
          @cr.host_interfaces_attrs(host)
        end
        assert err.message.end_with?('Invalid identifier interface[0]. Must be net[n] with n integer >= 0')
      end

      it 'sets compute id with identifier, ip and ip6' do
        ip = IPAddr.new(1, Socket::AF_INET).to_s
        ip6 = Array.new(4) { format('%<x>s', x: rand(16**4)) }.join(':') + '::1'
        physical_nic = FactoryBot.build(:nic_base_empty, :identifier => 'net0', :ip => ip, :ip6 => ip6)
        host = FactoryBot.build(
          :host_empty,
          :interfaces => [physical_nic],
          :compute_attributes => {
            'type' => 'qemu',
            'interfaces_attributes' => {
              '0' => physical_nic
            }
          }
        )
        nic_attributes = @cr.host_interfaces_attrs(host).values.select(&:present?)
        nic_attr = nic_attributes.first
        assert_equal 'net0', nic_attr[:id]
        assert_equal ip, nic_attr[:ip]
        assert_equal ip6, nic_attr[:ip6]
      end
    end
  end
end
