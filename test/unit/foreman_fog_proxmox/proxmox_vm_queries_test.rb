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
require 'ostruct'

module ForemanFogProxmox
  class ProxmoxVMQueriesTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVMHelper

    describe 'nodes' do
      before do
        @cr = ForemanFogProxmox::Proxmox.new
        @nodes = mock('nodes')
        client = mock('client')
        client.stubs(:nodes).returns(@nodes)
        @cr.stubs(:client).returns(client)
      end

      it 'returns the complete node inventory sorted by name' do
        node_z = OpenStruct.new(node: 'node-z', status: 'online')
        node_a = OpenStruct.new(node: 'node-a', status: 'offline')
        @nodes.stubs(:all).returns([node_z, node_a])

        assert_equal %w[node-a node-z], @cr.nodes.map(&:node)
      end

      it 'excludes offline nodes' do
        online = OpenStruct.new(node: 'online', status: 'online')
        offline = OpenStruct.new(node: 'offline', status: 'offline')
        @nodes.stubs(:all).returns([offline, online])

        availability = @cr.node_availability

        assert_equal [online], availability[:available]
        assert_equal [offline], availability[:offline]
        assert_equal [online], @cr.available_nodes
        assert_equal [offline], @cr.offline_nodes
        assert_equal [offline, online], @cr.nodes
      end

      it 'keeps nodes without a status for compatibility' do
        node = OpenStruct.new(node: 'unknown')
        @nodes.stubs(:all).returns([node])

        assert_equal [node], @cr.nodes
        assert_equal [node], @cr.available_nodes
      end

      it 'returns an empty available list when all nodes are offline' do
        offline = OpenStruct.new(node: 'offline', status: 'offline')
        @nodes.stubs(:all).returns([offline])

        assert_equal [offline], @cr.nodes
        assert_empty @cr.available_nodes
        assert_equal [offline], @cr.node_availability[:offline]
      end

      it 'refreshes availability when a node goes offline' do
        online = OpenStruct.new(node: 'online', status: 'online')
        @nodes.expects(:all).twice.returns([online], [OpenStruct.new(node: 'online', status: 'offline')])

        assert_equal [online], @cr.available_nodes
        assert_empty @cr.available_nodes
      end

      it 'does not query VM collections on offline nodes' do
        offline_servers = mock('offline servers')
        offline_containers = mock('offline containers')
        offline_servers.expects(:all).never
        offline_containers.expects(:all).never
        offline = OpenStruct.new(
          node: 'offline',
          status: 'offline',
          servers: offline_servers,
          containers: offline_containers
        )
        online_servers = mock('online servers')
        online_containers = mock('online containers')
        online_servers.stubs(:all).returns([])
        online_containers.stubs(:all).returns([])
        online = OpenStruct.new(
          node: 'online',
          status: 'online',
          servers: online_servers,
          containers: online_containers
        )
        @nodes.stubs(:all).returns([offline, online])

        assert_empty @cr.vms.items
      end
    end

    describe 'storages' do
      before do
        @cr = ForemanFogProxmox::Proxmox.new
        @storages_collection = mock('storages_collection')
        @node = mock('node')
        @node.stubs(:storages).returns(@storages_collection)
        nodes = mock('nodes')
        nodes.stubs(:get).with('proxmox').returns(@node)
        client = mock('client')
        client.stubs(:nodes).returns(nodes)
        @cr.stubs(:client).returns(client)
      end

      it 'returns only active and enabled storages' do
        active_storage = OpenStruct.new(storage: 'local', enabled: 1, active: 1)
        @storages_collection.stubs(:list_by_content_type).with('images').returns([active_storage])

        assert_equal [active_storage], @cr.storages('proxmox')
      end

      it 'returns active storages sorted by storage name' do
        storage_zfs = OpenStruct.new(storage: 'local-zfs', enabled: 1, active: 1)
        storage_lvm = OpenStruct.new(storage: 'local-lvm', enabled: 1, active: 1)
        @storages_collection.stubs(:list_by_content_type).with('images').returns([storage_zfs, storage_lvm])

        assert_equal %w[local-lvm local-zfs], @cr.storages('proxmox').map(&:storage)
      end

      it 'returns all active enabled storage types when no content filter is specified' do
        media = OpenStruct.new(storage: 'local', content: 'iso,vztmpl,backup', enabled: 1, active: 1)
        rootfs = OpenStruct.new(storage: 'containers', content: 'rootdir', enabled: 1, active: 1)
        disk = OpenStruct.new(storage: 'disks', content: 'images', enabled: 1, active: 1)
        disabled = OpenStruct.new(storage: 'disabled', content: 'iso', enabled: 0, active: 1)
        inactive = OpenStruct.new(storage: 'inactive', content: 'vztmpl', enabled: 1, active: 0)
        @storages_collection.expects(:all).returns([media, rootfs, disk, disabled, inactive])
        @storages_collection.expects(:list_by_content_type).never

        assert_equal [rootfs, disk, media], @cr.storages('proxmox', nil)
      end

      it 'preserves explicit media content filters' do
        media = OpenStruct.new(storage: 'local', content: 'iso,vztmpl', enabled: 1, active: 1)
        @storages_collection.expects(:list_by_content_type).with('iso').returns([media])
        @storages_collection.expects(:list_by_content_type).with('vztmpl').returns([media])

        assert_equal [media], @cr.storages('proxmox', 'iso')
        assert_equal [media], @cr.storages('proxmox', 'vztmpl')
      end

      it 'filters invalid storages and keeps valid ones' do
        valid = OpenStruct.new(storage: 'good', enabled: 1, active: 1)
        invalid = OpenStruct.new(storage: 'bad', enabled: 0, active: 1)

        @storages_collection.stubs(:list_by_content_type).with('images').returns([valid, invalid])

        assert_equal [valid], @cr.storages('proxmox')
      end

      it 'excludes disabled storages (enabled=0)' do
        disabled_storage = OpenStruct.new(storage: 'disabled-store', enabled: 0, active: 1)
        @storages_collection.stubs(:list_by_content_type).with('images').returns([disabled_storage])

        assert_empty @cr.storages('proxmox')
      end

      it 'excludes inactive storages (active=0)' do
        inactive_storage = OpenStruct.new(storage: 'inactive-store', enabled: 1, active: 0)
        @storages_collection.stubs(:list_by_content_type).with('images').returns([inactive_storage])

        assert_empty @cr.storages('proxmox')
      end

      it 'treats nil enabled as inactive and excludes it' do
        nil_enabled_storage = OpenStruct.new(storage: 'nil-enabled', enabled: nil, active: 1)
        @storages_collection.stubs(:list_by_content_type).with('images').returns([nil_enabled_storage])

        assert_empty @cr.storages('proxmox')
      end

      it 'treats nil active as inactive and excludes it' do
        nil_active_storage = OpenStruct.new(storage: 'nil-active', enabled: 1, active: nil)
        @storages_collection.stubs(:list_by_content_type).with('images').returns([nil_active_storage])

        assert_empty @cr.storages('proxmox')
      end
    end

    describe 'find_vm_by_uuid' do
      it 'skips offline nodes when finding a VM' do
        cr = ForemanFogProxmox::Proxmox.new
        offline = stub('offline', node: 'offline', status: 'offline')
        offline.expects(:servers).never
        offline.expects(:containers).never
        servers = mock('servers')
        online = mock('online', node: 'online', status: 'online', servers: servers)
        online.expects(:containers).never
        vm = mock('vm')
        cr.expects(:nodes).once.returns([offline, online])
        cr.expects(:find_vm_in_servers_by_vmid).with(servers, '100').returns(vm)

        assert_equal vm, cr.find_vm_by_uuid('1_100')
      end

      it 'returns nil when the uuid does not match' do
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, empty_servers, empty_servers)
        assert_nil cr.find_vm_by_uuid('1_100')
      end

      [true, false].each do |has_online_node|
        it "reports an inconclusive lookup when #{has_online_node ? 'some' : 'all'} nodes are offline" do
          cr = ForemanFogProxmox::Proxmox.new
          offline = mock('offline', node: 'node-a', status: 'offline')
          offline.expects(:servers).never
          offline.expects(:containers).never
          nodes = [offline]
          nodes << stub(node: 'node-b', status: 'online', servers: empty_servers, containers: empty_servers) if has_online_node
          cr.expects(:nodes).once.returns(nodes)

          error = assert_raises(::Foreman::Exception) { cr.find_vm_by_uuid('1_100') }

          assert_equal 'Unable to locate Proxmox VM 100: nodes node-a were offline and were not searched', error.bare_message
        end
      end

      it 'returns nil for an invalid UUID without searching nodes' do
        cr = ForemanFogProxmox::Proxmox.new
        cr.expects(:nodes).never

        assert_nil cr.find_vm_by_uuid('invalid')
      end

      it 'returns nil when both VM collections report not found' do
        missing = Fog::Errors::NotFound.new
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new,
          servers_raising_exception(missing), servers_raising_exception(missing))

        assert_nil cr.find_vm_by_uuid('1_100')
      end

      it 'raises an explicit lookup error when the compute raises error' do
        exception = Fog::Errors::Error.new('API unavailable')
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers_raising_exception(exception))

        error = assert_raises(::Foreman::Exception) { cr.find_vm_by_uuid('1_100') }

        assert_equal 'Failed retrieving Proxmox VM 100: API unavailable', error.bare_message
      end

      it 'does not treat a metadata lookup failure as an absent VM' do
        vm = mock('vm')
        servers = stub(get: vm)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.expects(:pool_owner).with(vm).raises(Fog::Errors::NotFound.new('pool metadata unavailable'))

        error = assert_raises(::Foreman::Exception) { cr.find_vm_by_uuid('1_100') }

        assert_equal 'Failed retrieving Proxmox VM 100: pool metadata unavailable', error.bare_message
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
