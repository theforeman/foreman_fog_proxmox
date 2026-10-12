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
require 'active_support/core_ext/hash/indifferent_access'

module ForemanFogProxmox
  class ProxmoxVMCommandsServerTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers

    describe 'clone_from_image' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
        @vmid = 101
        @collection = mock('collection')
        @image = stub('image', identity: '100', collection: @collection)
        @clone = stub('clone', vmid: @vmid, node_id: 'node-a')
        @collection.expects(:new).with(vmid: @vmid).returns(@clone)
        @image.expects(:destroy).never
        @cr.expects(:find_vm_by_uuid).never
      end

      it 'loads the clone directly and preserves pool and compute resource metadata' do
        @image.expects(:clone).with(@vmid).returns(@image)
        @clone.expects(:reload).returns(@clone)
        @cr.expects(:pool_owner).with(@clone)
        @clone.expects(:compute_resource_id=).with(@cr.id)

        assert_same @clone, @cr.clone_from_image(@image, @vmid)
      end

      it 'does not delete the requested VM ID when cloning fails' do
        failure = Fog::Errors::Error.new('clone failed')
        @image.expects(:clone).with(@vmid).raises(failure)
        @clone.expects(:reload).never
        @clone.expects(:destroy).never

        assert_same failure, assert_raises(Fog::Errors::Error) { @cr.clone_from_image(@image, @vmid) }
      end

      [nil, Fog::Errors::Error.new('status unavailable')].each do |result|
        it "cleans up after successful cloning when initial refresh #{result ? 'raises' : 'returns nil'}" do
          @image.expects(:clone).with(@vmid)
          reloads = @clone.expects(:reload).twice
          result ? reloads.raises(result).then.returns(@clone) : reloads.returns(nil, @clone)
          @clone.expects(:ready?).returns(false)
          @clone.expects(:ha).returns(nil)
          @clone.expects(:destroy).returns(true)
          @cr.expects(:pool_owner).never

          error = assert_raises(result ? Fog::Errors::Error : ::Foreman::Exception) { @cr.clone_from_image(@image, @vmid) }
          assert_same result, error if result
        end
      end

      it 'cleans up the clone if loading its pool metadata fails' do
        @image.expects(:clone).with(@vmid)
        @clone.expects(:reload).twice.returns(@clone)
        failure = Fog::Errors::Error.new('pool unavailable')
        @cr.expects(:pool_owner).with(@clone).raises(failure)
        @clone.expects(:ready?).returns(false)
        @clone.expects(:ha).returns(nil)
        @clone.expects(:destroy).returns(true)

        assert_same failure, assert_raises(Fog::Errors::Error) { @cr.clone_from_image(@image, @vmid) }
      end

      it 'reports failed clone cleanup without deleting from stale state' do
        @image.expects(:clone).with(@vmid)
        @clone.expects(:reload).twice.returns(nil)
        @clone.expects(:ready?).never
        @clone.expects(:destroy).never
        @cr.logger.expects(:error).with(regexp_matches(/Failed to clean up Proxmox VM 101 on node node-a/))

        error = assert_raises(::Foreman::Exception) { @cr.clone_from_image(@image, @vmid) }

        assert_equal 'Unable to refresh Proxmox VM 101 on node node-a', error.bare_message
      end
    end

    describe 'known-node clones' do
      %w[qemu lxc].each do |type|
        it "loads a real Fog #{type} clone without consulting cluster availability" do
          cr = FactoryBot.build_stubbed(:proxmox_cr)
          service = stub(list_tasks: [])
          collection = Fog::Proxmox::Compute::Servers.new(service: service, node_id: 'node-a', type: type)
          image = collection.new(vmid: 999, status: 'stopped')
          loaded_clone = collection.new(vmid: 101, status: 'stopped')
          image.expects(:request).with(:clone_server, { newid: 101 }, vmid: 999).returns(true)
          collection.expects(:get).with(999).returns(image)
          collection.expects(:get).with(101).returns(loaded_clone)
          cr.expects(:nodes).never
          cr.expects(:find_vm_by_uuid).never
          cr.stubs(:pools).returns([])

          clone = cr.clone_from_image(image, 101)

          assert_equal 101, clone.vmid
          assert_equal 'node-a', clone.node_id
          assert_equal type, clone.type
          assert_equal cr.id, clone.compute_resource_id
          assert_equal 999, image.vmid
        end
      end
    end

    describe 'available_images' do
      it 'removes duplicates' do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
        clone = mock('vm')
        clone.stubs(:name).returns('vm-1')
        @cr.stubs(:find_vm_by_uuid).returns(clone)
        template = mock('template')
        template.stubs(:vmid).returns(100).at_least(2)
        @cr.stubs(:templates).returns([template, template])
        assert_equal 1, @cr.available_images.length
      end
    end

    describe 'templates' do
      it 'does not query storages on offline nodes' do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
        online = mock('online', node: 'online', status: 'online')
        offline = stub('offline', node: 'offline', status: 'offline')
        volumes = mock('volumes')
        storage = stub('storage', enabled: 1, volumes: volumes)
        template = mock('template', template?: true)

        @cr.stubs(:nodes).returns([offline, online])
        @cr.expects(:storages).with('online').returns([storage])
        @cr.expects(:storages).with('offline').never
        volumes.expects(:list_by_content_type).with('images').returns([template])
        volumes.expects(:list_by_content_type).with('rootdir').returns([])

        assert_equal [template], @cr.templates
      end
    end
  end
end
