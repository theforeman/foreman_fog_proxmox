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
  class ProxmoxVmQueriesTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVmHelper

    describe 'find_vm_by_uuid' do
      it 'returns nil when the uuid does not match' do
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, empty_servers, empty_servers)
        assert cr.find_vm_by_uuid('1_100').nil?
      end

      it 'raises RecordNotFound when the compute raises error' do
        exception = Fog::Errors::Error.new
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers_raising_exception(exception))
        assert_raises ActiveRecord::RecordNotFound do
          cr.find_vm_by_uuid('1_100')
        end
      end

      it 'finds vm on other node in cluster' do
        args = { vmid: '100', type: 'qemu' }
        servers = mock('servers')
        vm = mock('vm')
        vm.stubs(:vmid).returns(args[:vmid])
        config = mock('config')
        config.expects(:pool=, nil)
        vm.stubs(:config).returns(config)
        servers.stubs(:id_valid?).returns(true)
        servers.stubs(:get).with(args[:vmid]).returns(vm)
        cr = mock_cluster_nodes_servers_containers(
          ForemanFogProxmox::Proxmox.new,
          empty_servers, empty_servers, # node1
          servers, empty_servers        # node2
        )
        assert_equal vm, cr.find_vm_by_uuid('1_' + args[:vmid])
      end
    end
  end
end
