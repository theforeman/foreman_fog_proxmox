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

module ForemanFogProxmox
  class ComputeResourcesControllerTest < ActionController::TestCase
    tests ForemanFogProxmox::ComputeResourcesController

    setup do
      @compute_resource = FactoryBot.create(:proxmox_cr)
      mock_storage = mock('storage')
      mock_storage.stubs(:storage).returns('local')
      mock_storage.stubs(:volumes).returns([])

      @compute_resource.stubs(:images_by_storage).returns([])
      @compute_resource.stubs(:nodes).returns([])
      @compute_resource.stubs(:pools).returns([])
      @compute_resource.stubs(:storages).with('proxmox').returns([mock_storage])
      @compute_resource.stubs(:storages).with('proxmox', 'vztmpl').returns([])
      @compute_resource.stubs(:storages).with('proxmox', 'iso').returns([])
      @compute_resource.stubs(:storages).with(nil).returns([])
      @compute_resource.stubs(:bridges).returns([])

      # Stub ComputeResource.find to return our stubbed instance
      ComputeResource.stubs(:find).with(@compute_resource.id).returns(@compute_resource)
      ComputeResource.stubs(:find).with(@compute_resource.id.to_s).returns(@compute_resource)
    end

    test 'should get isos by node and storage' do
      get :isos_by_id_and_node_and_storage,
        params: { :compute_resource_id => @compute_resource.id, :node_id => 'proxmox', :storage => 'local' }
      assert_response :found
      show_response = @response.body
      assert_not show_response.empty?
    end
    test 'should get ostemplates by node and storage' do
      get :ostemplates_by_id_and_node_and_storage,
        params: { :compute_resource_id => @compute_resource.id, :node_id => 'proxmox', :storage => 'local' }
      assert_response :found
      show_response = @response.body
      assert_not show_response.empty?
    end
    test 'should get isos by node' do
      get :isos_by_id_and_node, params: { :compute_resource_id => @compute_resource.id, :node_id => 'proxmox' }
      assert_response :found
      show_response = @response.body
      assert_not show_response.empty?
    end
    test 'should get ostemplates by node' do
      get :ostemplates_by_id_and_node, params: { :compute_resource_id => @compute_resource.id, :node_id => 'proxmox' }
      assert_response :found
      show_response = @response.body
      assert_not show_response.empty?
    end
    test 'should get volumes by node and storage' do
      get :volumes_by_node_and_storage,
        params: { :compute_resource_id => @compute_resource.id, :node_id => 'proxmox', :storage => 'local' },
        session: set_session_user
      assert_response :success
      show_response = @response.body
      assert_not show_response.empty?
      json_response = JSON.parse(show_response)
      assert_instance_of Array, json_response
    end
    test 'should get metadata' do
      node_a = stub(node: 'node-a')
      node_b = stub(node: 'node-b')
      node_a_storages = [{ storage: 'shared-iso', content: 'iso', avail: 100, used: 20, total: 120, shared: 1 }]
      node_b_storages = [{ storage: 'local', content: 'iso', avail: 200, used: 30, total: 230, shared: 0 }]
      node_a_bridges = [{ iface: 'vmbr0' }]
      node_b_bridges = [{ iface: 'vmbr1' }]
      @compute_resource.stubs(:nodes).returns([node_a, node_b])
      @compute_resource.expects(:storages).with('node-a').returns(node_a_storages)
      @compute_resource.expects(:storages).with('node-b').returns(node_b_storages)
      @compute_resource.expects(:bridges).with('node-a').returns(node_a_bridges)
      @compute_resource.expects(:bridges).with('node-b').returns(node_b_bridges)

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user
      assert_response :success
      show_response = @response.body
      assert_not show_response.empty?
      json_response = JSON.parse(show_response)
      assert_instance_of Hash, json_response
      assert json_response.key?('nodes')
      assert json_response.key?('pools')
      assert json_response.key?('storages')
      assert json_response.key?('bridges')
      assert_instance_of Array, json_response['nodes']
      assert_instance_of Array, json_response['pools']
      assert_instance_of Array, json_response['storages']
      assert_instance_of Array, json_response['bridges']
      assert_equal ['node-a', 'node-b'], (json_response['storages'].map { |storage| storage['node_id'] })
      assert_equal [1, 0], (json_response['storages'].map { |storage| storage['shared'] })
      assert_equal ['node-a', 'node-b'], (json_response['bridges'].map { |bridge| bridge['node_id'] })
      assert_equal ['vmbr0', 'vmbr1'], (json_response['bridges'].map { |bridge| bridge['iface'] })
      assert_empty json_response['skipped_nodes']
    end

    test 'node listing errors propagate instead of returning partial metadata' do
      error = StandardError.new('node listing unavailable')
      @compute_resource.expects(:nodes).raises(error)

      raised = assert_raises(StandardError) do
        @controller.send(:extract_node_metadata, @compute_resource)
      end
      assert_same error, raised
    end

    ['pools', 'images'].each do |section|
      test "metadata preserves other sections when #{section} fails" do
        @compute_resource.stubs(:nodes).returns([stub(node: 'healthy')])
        @compute_resource.stubs(:storages).with('healthy').returns([{ storage: 'local' }])
        @compute_resource.stubs(:bridges).with('healthy').returns([{ iface: 'vmbr0' }])
        @compute_resource.stubs(:pools).returns([{ poolid: 'pool-a' }])
        @compute_resource.stubs(:images).returns([{ uuid: nil, name: 'image-a' }])
        error = StandardError.new("#{section} unavailable")
        @compute_resource.expects(section.to_sym).raises(error)
        Foreman::Logging.expects(:exception).with(
          "Failed to load Proxmox #{section} for compute resource #{@compute_resource.id}", error
        )

        get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user

        assert_response :success
        metadata = JSON.parse(@response.body)
        assert_empty metadata[section]
        assert_equal [{ 'node' => 'healthy' }], metadata['nodes']
        assert_equal ['local'], (metadata['storages'].map { |storage| storage['storage'] })
        assert_equal [{ 'node_id' => 'healthy', 'iface' => 'vmbr0' }], metadata['bridges']
        other_section = section == 'pools' ? 'images' : 'pools'
        assert_equal 1, metadata[other_section].size
      end
    end

    test 'metadata tolerates and logs both pool and image failures' do
      ['pools', 'images'].each do |section|
        error = StandardError.new("#{section} unavailable")
        @compute_resource.expects(section.to_sym).raises(error)
        Foreman::Logging.expects(:exception).with(
          "Failed to load Proxmox #{section} for compute resource #{@compute_resource.id}", error
        )
      end

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user

      assert_response :success
      metadata = JSON.parse(@response.body)
      assert_empty metadata['pools']
      assert_empty metadata['images']
    end

    test 'metadata skips nodes when storage or bridge requests fail and continues processing' do
      @compute_resource.stubs(:nodes).returns([
                                                stub(node: 'storage-failure'), stub(node: 'bridge-failure'), stub(node: 'healthy')
                                              ])
      storage_error = StandardError.new('storage request failed')
      bridge_error = StandardError.new('bridge request failed')
      @compute_resource.expects(:storages).with('storage-failure').raises(storage_error)
      @compute_resource.expects(:bridges).with('storage-failure').never
      @compute_resource.expects(:storages).with('bridge-failure').returns([{ storage: 'discarded' }])
      @compute_resource.expects(:bridges).with('bridge-failure').raises(bridge_error)
      @compute_resource.expects(:storages).with('healthy').returns([{ storage: 'local' }])
      @compute_resource.expects(:bridges).with('healthy').returns([{ iface: 'vmbr0' }])
      Foreman::Logging.expects(:exception).with('Failed to load Proxmox metadata for node storage-failure', storage_error)
      Foreman::Logging.expects(:exception).with('Failed to load Proxmox metadata for node bridge-failure', bridge_error)

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user

      assert_response :success
      metadata = JSON.parse(@response.body)
      assert_equal [{ 'node' => 'healthy' }], metadata['nodes']
      assert_equal ['healthy'], (metadata['storages'].map { |storage| storage['node_id'] })
      assert_equal ['local'], (metadata['storages'].map { |storage| storage['storage'] })
      assert_equal [{ 'node_id' => 'healthy', 'iface' => 'vmbr0' }], metadata['bridges']
      assert_equal ['storage-failure', 'bridge-failure'], metadata['skipped_nodes']
      assert metadata.key?('pools')
      assert metadata.key?('images')
    end

    test 'metadata returns empty node metadata when all nodes fail' do
      @compute_resource.stubs(:nodes).returns([stub(node: 'offline')])
      error = StandardError.new('node is offline')
      @compute_resource.expects(:storages).with('offline').raises(error)
      Foreman::Logging.expects(:exception).with('Failed to load Proxmox metadata for node offline', error)

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user

      assert_response :success
      metadata = JSON.parse(@response.body)
      assert_empty metadata['nodes']
      assert_empty metadata['storages']
      assert_empty metadata['bridges']
      assert_equal ['offline'], metadata['skipped_nodes']
    end

    test 'metadata includes shared storage for every node where it is available' do
      node_a = stub(node: 'node-a')
      node_b = stub(node: 'node-b')
      shared_storage = {
        storage: 'shared-iso',
        content: 'iso',
        avail: 100,
        used: 20,
        total: 120,
        shared: 1,
      }
      @compute_resource.stubs(:nodes).returns([node_a, node_b])
      @compute_resource.expects(:storages).with('node-a').returns([shared_storage])
      @compute_resource.expects(:storages).with('node-b').returns([shared_storage])

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user
      assert_response :success
      json_response = JSON.parse(@response.body)

      assert_equal [
        ['shared-iso', 'node-a'],
        ['shared-iso', 'node-b'],
      ], (json_response['storages'].map { |storage| [storage['storage'], storage['node_id']] })
    end
  end
end
