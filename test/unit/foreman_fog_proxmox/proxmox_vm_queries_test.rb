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
      it 'caches nodes for persisted compute resources' do
        cr = FactoryBot.build_stubbed(:proxmox_cr, :caching_enabled => true)
        node_z = OpenStruct.new(node: 'z-proxmox')
        node_a = OpenStruct.new(node: 'a-proxmox')
        nodes = mock('nodes')
        nodes.expects(:all).once.returns([node_z, node_a])
        client = mock('client')
        client.stubs(:nodes).returns(nodes)
        cr.stubs(:client).returns(client)

        assert_equal %w[a-proxmox z-proxmox], cr.nodes.map(&:node)
        assert_equal %w[a-proxmox z-proxmox], cr.nodes.map(&:node)
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

        assert_equal [active_storage.storage], @cr.storages('proxmox').map(&:storage)
      end

      it 'returns active storages sorted by storage name' do
        storage_zfs = OpenStruct.new(storage: 'local-zfs', enabled: 1, active: 1)
        storage_lvm = OpenStruct.new(storage: 'local-lvm', enabled: 1, active: 1)
        @storages_collection.stubs(:list_by_content_type).with('images').returns([storage_zfs, storage_lvm])

        assert_equal %w[local-lvm local-zfs], @cr.storages('proxmox').map(&:storage)
      end

      it 'filters invalid storages and keeps valid ones' do
        valid = OpenStruct.new(storage: 'good', enabled: 1, active: 1)
        invalid = OpenStruct.new(storage: 'bad', enabled: 0, active: 1)

        @storages_collection.stubs(:list_by_content_type).with('images').returns([valid, invalid])

        assert_equal [valid.storage], @cr.storages('proxmox').map(&:storage)
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

      it 'caches storages by node and content type for persisted compute resources' do
        cr = FactoryBot.build_stubbed(:proxmox_cr, :caching_enabled => true)
        active_storage = OpenStruct.new(storage: 'local', enabled: 1, active: 1)
        storages_collection = mock('storages_collection')
        storages_collection.expects(:list_by_content_type).with('images').once.returns([active_storage])
        node = mock('node')
        node.stubs(:storages).returns(storages_collection)
        nodes = mock('nodes')
        nodes.stubs(:get).with('proxmox').returns(node)
        client = mock('client')
        client.stubs(:nodes).returns(nodes)
        cr.stubs(:client).returns(client)

        assert_equal [active_storage.storage], cr.storages('proxmox').map(&:storage)
        assert_equal [active_storage.storage], cr.storages('proxmox').map(&:storage)
      end
    end

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
  end
end
