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
