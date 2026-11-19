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

    describe 'node availability' do
      before do
        @cr = ForemanFogProxmox::Proxmox.new
        @online = OpenStruct.new(node: 'online-node', status: 'online')
        @offline = OpenStruct.new(node: 'offline-node', status: 'offline')
        @nodes = mock('nodes')
        client = mock('client')
        client.stubs(:nodes).returns(@nodes)
        @cr.stubs(:client).returns(client)
      end

      it 'returns only online nodes' do
        @nodes.stubs(:all).returns([@offline, @online])

        assert_equal [@online], @cr.available_nodes
        assert @cr.online_node?(@online)
        assert_not @cr.online_node?(@offline)
      end

      it 'returns the requested online node' do
        @nodes.expects(:get).with('online-node').returns(@online)

        assert_equal @online, @cr.find_online_node!('online-node')
      end

      it 'raises when the requested node is missing' do
        @nodes.expects(:get).with('missing').returns(nil)

        error = assert_raises(Foreman::Exception) { @cr.find_online_node!('missing') }
        assert_includes error.message, "Proxmox node 'missing' not found"
      end

      it 'raises when the requested node is offline' do
        @nodes.expects(:get).with('offline-node').returns(@offline)

        error = assert_raises(Foreman::Exception) { @cr.find_online_node!('offline-node') }
        assert_includes error.message, "Proxmox node 'offline-node' is not online"
      end

      it 'does not query bridges on an offline node' do
        @cr.stubs(:network_client).returns(stub(nodes: @nodes))
        @nodes.expects(:get).with('offline-node').returns(@offline)
        @offline.expects(:networks).never

        assert_empty @cr.bridges('offline-node')
      end
    end

    describe 'vms' do
      it 'lists servers and containers only from online nodes' do
        cr = ForemanFogProxmox::Proxmox.new
        server = stub('server')
        container = stub('container')
        online = stub(status: 'online', servers: stub(all: [server]), containers: stub(all: [container]))
        offline = stub(status: 'offline')
        offline.expects(:servers).never
        offline.expects(:containers).never
        cr.stubs(:nodes).returns([offline, online])

        assert_equal [server, container], cr.vms.all
      end
    end

    describe 'storages' do
      before do
        @cr = ForemanFogProxmox::Proxmox.new
        @storages_collection = mock('storages_collection')
        @node = mock('node')
        @node.stubs(:status).returns('online')
        @node.stubs(:storages).returns(@storages_collection)
        nodes = mock('nodes')
        nodes.stubs(:get).with('proxmox').returns(@node)
        client = mock('client')
        client.stubs(:nodes).returns(nodes)
        @cr.stubs(:client).returns(client)
      end

      it 'does not query storages on an offline node' do
        @node.stubs(:status).returns('offline')
        @node.expects(:storages).never

        assert_empty @cr.storages('proxmox')
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
      it 'returns nil when the uuid does not match' do
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, empty_servers, empty_servers)
        cr.nodes.each { |node| node.stubs(:status).returns('online') }
        assert_nil cr.find_vm_by_uuid('1_100')
      end

      it 'preserves the original exception when the compute raises error' do
        exception = Fog::Errors::Error.new
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers_raising_exception(exception))
        cr.nodes.each { |node| node.stubs(:status).returns('online') }
        error = assert_raises Fog::Errors::Error do
          cr.find_vm_by_uuid('1_100')
        end
        assert_same exception, error
      end

      it 'reports offline nodes when the vm cannot be found' do
        cr = ForemanFogProxmox::Proxmox.new
        offline = mock('offline node', node: 'node1', status: 'offline')
        online = mock('online node', status: 'online', servers: empty_servers, containers: empty_servers)
        online.stubs(:node).returns('node2')
        offline.expects(:servers).never
        offline.expects(:containers).never
        cr.stubs(:nodes).returns([offline, online])

        error = assert_raises(Foreman::Exception) { cr.find_vm_by_uuid('1_100') }
        assert_includes error.message, 'Cannot locate VM 100. Some Proxmox nodes are offline: node1'
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
        cr.nodes.each { |node| node.stubs(:status).returns('online') }
        cr.nodes.first.stubs(:status).returns('offline')
        cr.nodes.first.expects(:servers).never
        cr.nodes.first.expects(:containers).never
        assert_equal vm, cr.find_vm_by_uuid('1_' + args[:vmid])
      end
    end
  end
end
