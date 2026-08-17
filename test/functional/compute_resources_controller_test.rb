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
    end
    test 'should return storages from all nodes in metadata' do
      nodes = [OpenStruct.new(node: 'proxmox1'), OpenStruct.new(node: 'proxmox2')]
      ceph1 = OpenStruct.new(storage: 'ceph', content: 'images', avail: 5_000, used: 1_000, total: 6_000)
      ceph2 = OpenStruct.new(storage: 'ceph', content: 'images', avail: 5_000, used: 1_000, total: 6_000)
      @compute_resource.stubs(:nodes).returns(nodes)
      @compute_resource.stubs(:storages).with('proxmox1').returns([ceph1])
      @compute_resource.stubs(:storages).with('proxmox2').returns([ceph2])
      @compute_resource.stubs(:bridges).with('proxmox1').returns([])
      @compute_resource.stubs(:bridges).with('proxmox2').returns([])

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user
      assert_response :success

      storages = JSON.parse(@response.body)['storages']
      storage_nodes = storages.map { |storage| [storage['storage'], storage['node_id']] }
      assert_equal [['ceph', 'proxmox1'], ['ceph', 'proxmox2']], storage_nodes
    end
    test 'should return bridges from all nodes in metadata' do
      nodes = [OpenStruct.new(node: 'proxmox1'), OpenStruct.new(node: 'proxmox2')]
      vmbr1 = OpenStruct.new(iface: 'vmbr0')
      vmbr2 = OpenStruct.new(iface: 'vmbr0')
      @compute_resource.stubs(:nodes).returns(nodes)
      @compute_resource.stubs(:storages).with('proxmox1').returns([])
      @compute_resource.stubs(:storages).with('proxmox2').returns([])
      @compute_resource.stubs(:bridges).with('proxmox1').returns([vmbr1])
      @compute_resource.stubs(:bridges).with('proxmox2').returns([vmbr2])

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user
      assert_response :success

      bridges = JSON.parse(@response.body)['bridges']
      bridge_nodes = bridges.map { |bridge| [bridge['iface'], bridge['node_id']] }
      assert_equal [['vmbr0', 'proxmox1'], ['vmbr0', 'proxmox2']], bridge_nodes
    end
    test 'should fetch nodes once while building metadata' do
      nodes = [OpenStruct.new(node: 'proxmox1'), OpenStruct.new(node: 'proxmox2')]
      @compute_resource.expects(:nodes).once.returns(nodes)
      @compute_resource.stubs(:storages).with('proxmox1').returns([])
      @compute_resource.stubs(:storages).with('proxmox2').returns([])
      @compute_resource.stubs(:bridges).with('proxmox1').returns([])
      @compute_resource.stubs(:bridges).with('proxmox2').returns([])

      get :metadata, params: { :compute_resource_id => @compute_resource.id }, session: set_session_user
      assert_response :success
    end
  end
end
