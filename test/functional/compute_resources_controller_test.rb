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
require 'fog/proxmox/attributes'
require 'fog/proxmox/compute/models/storages'
require 'fog/proxmox/compute/models/volumes'

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
      @compute_resource.stubs(:storages).with('proxmox', nil).returns([mock_storage])
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
      node_a = stub(node: 'node-a', status: 'online')
      node_b = stub(node: 'node-b', status: 'online')
      offline_node = stub(node: 'node-offline', status: 'offline')
      node_a_storages = [{ storage: 'shared-iso', content: 'iso', avail: 100, used: 20, total: 120, shared: 1 }]
      node_b_storages = [{ storage: 'local', content: 'iso', avail: 200, used: 30, total: 230, shared: 0 }]
      node_a_bridges = [{ iface: 'vmbr0' }]
      node_b_bridges = [{ iface: 'vmbr1' }]
      @compute_resource.stubs(:nodes).returns([node_a, offline_node, node_b])
      @compute_resource.expects(:storages).with('node-offline', nil).returns([])
      @compute_resource.expects(:bridges).with('node-offline').returns([])
      @compute_resource.expects(:storages).with('node-a', nil).returns(node_a_storages)
      @compute_resource.expects(:storages).with('node-b', nil).returns(node_b_storages)
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
      assert_equal [
        { 'node' => 'node-a', 'status' => 'online' },
        { 'node' => 'node-offline', 'status' => 'offline' },
        { 'node' => 'node-b', 'status' => 'online' },
      ], json_response['nodes']
      assert_instance_of Array, json_response['pools']
      assert_instance_of Array, json_response['storages']
      assert_instance_of Array, json_response['bridges']
      assert_equal ['node-a', 'node-b'], (json_response['storages'].map { |storage| storage['node_id'] })
      assert_equal [1, 0], (json_response['storages'].map { |storage| storage['shared'] })
      assert_equal ['node-a', 'node-b'], (json_response['bridges'].map { |bridge| bridge['node_id'] })
      assert_equal ['vmbr0', 'vmbr1'], (json_response['bridges'].map { |bridge| bridge['iface'] })
      assert_empty json_response['skipped_nodes']
      assert_empty json_response['failed_metadata_sections']
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
        @compute_resource.stubs(:nodes).returns([stub(node: 'healthy', status: 'online')])
        @compute_resource.stubs(:storages).with('healthy', nil).returns([{ storage: 'local' }])
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
        assert_equal [section], metadata['failed_metadata_sections']
        assert_equal [{ 'node' => 'healthy', 'status' => 'online' }], metadata['nodes']
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
      assert_equal ['pools', 'images'], metadata['failed_metadata_sections']
    end

    test 'metadata preserves successful sections when storage or bridge requests fail' do
      @compute_resource.stubs(:nodes).returns([
                                                stub(node: 'storage-failure', status: 'online'),
                                                stub(node: 'bridge-failure', status: 'online'),
                                                stub(node: 'healthy', status: 'online'),
                                              ])
      storage_error = StandardError.new('storage request failed')
      bridge_error = StandardError.new('bridge request failed')
      @compute_resource.expects(:storages).with('storage-failure', nil).raises(storage_error)
      @compute_resource.expects(:bridges).with('storage-failure').returns([{ iface: 'vmbr1' }])
      @compute_resource.expects(:storages).with('bridge-failure', nil).returns([{ storage: 'preserved' }])
      @compute_resource.expects(:bridges).with('bridge-failure').raises(bridge_error)
      @compute_resource.expects(:storages).with('healthy', nil).returns([{ storage: 'local' }])
      @compute_resource.expects(:bridges).with('healthy').returns([{ iface: 'vmbr0' }])
      Foreman::Logging.expects(:exception).with('Failed to load Proxmox storages for node storage-failure', storage_error)
      Foreman::Logging.expects(:exception).with('Failed to load Proxmox bridges for node bridge-failure', bridge_error)

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user

      assert_response :success
      metadata = JSON.parse(@response.body)
      assert_equal ['storage-failure', 'bridge-failure', 'healthy'], (metadata['nodes'].map { |node| node['node'] })
      assert_equal ['bridge-failure', 'healthy'], (metadata['storages'].map { |storage| storage['node_id'] })
      assert_equal ['preserved', 'local'], (metadata['storages'].map { |storage| storage['storage'] })
      assert_equal ['storages:storage-failure', 'bridges:bridge-failure'], metadata['failed_metadata_sections']
      assert_equal [
        { 'node_id' => 'storage-failure', 'iface' => 'vmbr1' },
        { 'node_id' => 'healthy', 'iface' => 'vmbr0' },
      ], metadata['bridges']
      assert_empty metadata['skipped_nodes']
      assert metadata.key?('pools')
      assert metadata.key?('images')
    end

    ['storages', 'bridges'].each do |section|
      test "metadata keeps node when #{section} fails and the other section is empty" do
        @compute_resource.stubs(:nodes).returns([stub(node: 'partial', status: 'online')])
        @compute_resource.stubs(:storages).with('partial', nil).returns([])
        @compute_resource.stubs(:bridges).with('partial').returns([])
        error = StandardError.new("#{section} unavailable")
        args = section == 'storages' ? ['partial', nil] : ['partial']
        @compute_resource.expects(section.to_sym).with(*args).raises(error)
        Foreman::Logging.expects(:exception).with("Failed to load Proxmox #{section} for node partial", error)

        get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user

        assert_response :success
        metadata = JSON.parse(@response.body)
        assert_equal [{ 'node' => 'partial', 'status' => 'online' }], metadata['nodes']
        assert_equal ["#{section}:partial"], metadata['failed_metadata_sections']
        assert_empty metadata['storages']
        assert_empty metadata['bridges']
        assert_empty metadata['skipped_nodes']
      end
    end

    test 'metadata returns empty node metadata when all nodes fail' do
      @compute_resource.stubs(:nodes).returns([stub(node: 'offline')])
      error = StandardError.new('node is offline')
      @compute_resource.expects(:storages).with('offline', nil).raises(error)
      @compute_resource.expects(:bridges).with('offline').raises(error)
      Foreman::Logging.expects(:exception).with('Failed to load Proxmox storages for node offline', error)
      Foreman::Logging.expects(:exception).with('Failed to load Proxmox bridges for node offline', error)

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user

      assert_response :success
      metadata = JSON.parse(@response.body)
      assert_empty metadata['nodes']
      assert_empty metadata['storages']
      assert_empty metadata['bridges']
      assert_equal ['offline'], metadata['skipped_nodes']
      assert_equal ['storages:offline', 'bridges:offline'], metadata['failed_metadata_sections']
    end

    test 'metadata returns an empty node list when no nodes are available' do
      @compute_resource.expects(:storages).never
      @compute_resource.expects(:bridges).never

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user

      assert_response :success
      json_response = JSON.parse(@response.body)
      assert_empty json_response['nodes']
      assert_empty json_response['storages']
      assert_empty json_response['bridges']
    end

    test 'metadata includes shared storage for every node where it is available' do
      node_a = stub(node: 'node-a', status: 'online')
      node_b = stub(node: 'node-b', status: 'online')
      shared_storage = {
        storage: 'shared-iso',
        content: 'iso',
        avail: 100,
        used: 20,
        total: 120,
        shared: 1,
      }
      @compute_resource.stubs(:nodes).returns([node_a, node_b])
      @compute_resource.expects(:storages).with('node-a', nil).returns([shared_storage])
      @compute_resource.expects(:storages).with('node-b', nil).returns([shared_storage])

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user
      assert_response :success
      json_response = JSON.parse(@response.body)

      assert_equal [
        ['shared-iso', 'node-a'],
        ['shared-iso', 'node-b'],
      ], (json_response['storages'].map { |storage| [storage['storage'], storage['node_id']] })
    end

    test 'metadata includes media-only and container-only storage without disk image support' do
      inventory = [
        { storage: 'local', content: 'iso,vztmpl,backup', active: 1, enabled: 1 },
        { storage: 'containers', content: 'rootdir', active: 1, enabled: 1 },
        { storage: 'disks', content: 'images', active: 1, enabled: 1 },
        { storage: 'disabled', content: 'iso', active: 1, enabled: 0 },
        { storage: 'inactive', content: 'vztmpl', active: 0, enabled: 1 },
      ]
      service = storage_service(inventory)
      service.expects(:list_volumes).never
      @compute_resource.stubs(:nodes).returns([stub(node: 'proxmox', status: 'online')])

      get :metadata, params: { compute_resource_id: @compute_resource.id }, session: set_session_user

      assert_response :success
      storages = JSON.parse(@response.body)['storages']
      assert_equal %w[containers disks local], (storages.map { |storage| storage['storage'] })
      assert_equal %w[rootdir images iso,vztmpl,backup], (storages.map { |storage| storage['content'] })
      assert_equal ['proxmox'], storages.map { |storage| storage['node_id'] }.uniq
    end

    %w[iso vztmpl].each do |content|
      test "lists #{content} volumes from storage without disk image support" do
        service = storage_service([{ storage: 'local', content: content, active: 1, enabled: 1 }])
        volume = { volid: "local:#{content}/test", content: content }
        service.expects(:list_volumes).with('proxmox', 'local', {}).returns([volume])

        get :volumes_by_node_and_storage,
          params: { compute_resource_id: @compute_resource.id, node_id: 'proxmox', storage: 'local' },
          session: set_session_user

        assert_response :success
        assert_equal [volume.stringify_keys], JSON.parse(@response.body)
      end
    end

    private

    def storage_service(storages)
      service = mock('storage service')
      service.expects(:list_storages).with('proxmox', {}).returns(storages)
      collection = Fog::Proxmox::Compute::Storages.new(service: service, node_id: 'proxmox')
      node = stub(storages: collection, status: 'online')
      nodes = mock('nodes')
      nodes.expects(:get).with('proxmox').returns(node)
      @compute_resource.unstub(:storages)
      @compute_resource.stubs(:client).returns(stub(nodes: nodes))
      service
    end
  end
end
