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
  class ProxmoxVMQueriesTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVMHelper

    describe 'find_vm_by_uuid' do
      it 'returns nil when the uuid does not match' do
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, empty_servers, empty_servers)
        assert_nil cr.find_vm_by_uuid('1_100')
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

    describe 'storage_active?' do
      before do
        @cr = ForemanFogProxmox::Proxmox.new
        @cr.stubs(:logger).returns(stub_everything('logger'))
      end

      it 'returns true when storage is active and enabled' do
        storage = mock('storage')
        storage.stubs(:respond_to?).with(:active).returns(true)
        storage.stubs(:respond_to?).with(:enabled).returns(true)
        storage.stubs(:active).returns(1)
        storage.stubs(:enabled).returns(1)
        storage.stubs(:storage).returns('local-lvm')
        assert @cr.send(:storage_active?, storage)
      end

      it 'returns false when storage is inactive' do
        storage = mock('storage')
        storage.stubs(:respond_to?).with(:active).returns(true)
        storage.stubs(:respond_to?).with(:enabled).returns(true)
        storage.stubs(:active).returns(0)
        storage.stubs(:enabled).returns(1)
        storage.stubs(:storage).returns('local-lvm')
        assert_not @cr.send(:storage_active?, storage)
      end

      it 'returns false when storage is disabled' do
        storage = mock('storage')
        storage.stubs(:respond_to?).with(:active).returns(true)
        storage.stubs(:respond_to?).with(:enabled).returns(true)
        storage.stubs(:active).returns(1)
        storage.stubs(:enabled).returns(0)
        storage.stubs(:storage).returns('local-lvm')
        assert_not @cr.send(:storage_active?, storage)
      end

      it 'defaults to true when attributes are missing (older API)' do
        storage = mock('storage')
        storage.stubs(:respond_to?).with(:active).returns(false)
        storage.stubs(:respond_to?).with(:enabled).returns(false)
        storage.stubs(:storage).returns('ceph-pool')
        assert @cr.send(:storage_active?, storage)
      end
    end

    describe 'storages' do
      it 'filters out inactive storages' do
        active_storage = mock('active_storage')
        active_storage.stubs(:respond_to?).returns(true)
        active_storage.stubs(:active).returns(1)
        active_storage.stubs(:enabled).returns(1)
        active_storage.stubs(:storage).returns('ceph')

        inactive_storage = mock('inactive_storage')
        inactive_storage.stubs(:respond_to?).returns(true)
        inactive_storage.stubs(:active).returns(0)
        inactive_storage.stubs(:enabled).returns(1)
        inactive_storage.stubs(:storage).returns('local-lvm')

        storages_list = mock('storages_list')
        storages_list.stubs(:list_by_content_type).returns([active_storage, inactive_storage])

        node = mock('node')
        node.stubs(:node).returns('pve')
        node.stubs(:storages).returns(storages_list)

        nodes_collection = mock('nodes_collection')
        nodes_collection.stubs(:get).with('pve').returns(node)

        client = mock('client')
        client.stubs(:nodes).returns(nodes_collection)

        cr = ForemanFogProxmox::Proxmox.new
        cr.stubs(:logger).returns(stub_everything('logger'))
        cr.stubs(:client).returns(client)
        cr.stubs(:default_node).returns(node)

        result = cr.storages('pve')
        assert_equal ['ceph'], result.map(&:storage)
      end

      it 'returns empty array on error' do
        cr = ForemanFogProxmox::Proxmox.new
        cr.stubs(:logger).returns(stub_everything('logger'))
        cr.stubs(:client).raises(StandardError, 'connection refused')

        result = cr.storages('pve')
        assert_empty result
      end
    end

    describe 'default_bridge_id' do
      it 'returns first bridge identity' do
        bridge = mock('bridge')
        bridge.stubs(:identity).returns('vmbr0')

        cr = ForemanFogProxmox::Proxmox.new
        cr.stubs(:logger).returns(stub_everything('logger'))
        cr.stubs(:bridges).returns([bridge])

        assert_equal 'vmbr0', cr.send(:default_bridge_id)
      end

      it 'returns nil when no bridges available' do
        cr = ForemanFogProxmox::Proxmox.new
        cr.stubs(:logger).returns(stub_everything('logger'))
        cr.stubs(:bridges).returns([])

        assert_nil cr.send(:default_bridge_id)
      end
    end
  end
end
