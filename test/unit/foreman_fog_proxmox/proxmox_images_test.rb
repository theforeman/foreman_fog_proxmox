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
        @image = mock('vm', identity: '100')
        @image.expects(:clone)
        @clone = mock('vm')
      end
      it 'clones server from image' do
        @clone.stubs(:container?).returns(false)
        @cr.stubs(:find_vm_by_uuid).with(@cr.id.to_s + '_' + @vmid.to_s).returns(@clone)
        @cr.clone_from_image(@image, @vmid)
      end
      it 'clones container from image' do
        @clone.stubs(:container?).returns(true)
        @cr.stubs(:find_vm_by_uuid).with(@cr.id.to_s + '_' + @vmid.to_s).returns(@clone)
        @cr.clone_from_image(@image, @vmid)
      end
    end

    describe 'template lookup from available images' do
      %w[qemu lxc].each do |type|
        it "resolves a listed #{type} template to the full VM object" do
          cr = FactoryBot.build_stubbed(:proxmox_cr)
          client = mock('client')
          resource = { 'vmid' => 100, 'type' => type, 'template' => 1, 'name' => 'template' }
          client.expects(:list_cluster_resources).with(type: 'vm').once.returns([resource])
          cr.stubs(:client).returns(client)
          cr.stubs(:pool_owner)

          vm = mock('full VM')
          servers = mock('servers')
          containers = mock('containers')
          servers.expects(:get).with('100').returns(type == 'qemu' ? vm : nil)
          if type == 'lxc'
            containers.expects(:get).with('100').returns(vm)
          else
            containers.expects(:get).never
          end
          cr.stubs(:nodes).returns([stub('node', node: 'pve1', servers: servers, containers: containers)])

          image = cr.available_images.first

          assert_equal "#{cr.id}_100", image.id
          assert_same vm, cr.template(image.id)
        end
      end

      it 'returns nil when the template no longer exists' do
        cr = FactoryBot.build_stubbed(:proxmox_cr)
        cr.expects(:templates).never
        cr.stubs(:nodes).returns([])

        assert_nil cr.template("#{cr.id}_100")
      end
    end

    describe 'available_images' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
        @client = mock('client')
        @cr.stubs(:client).returns(@client)
        @client.expects(:nodes).never
        @cr.expects(:find_vm_by_uuid).never
      end

      it 'lists QEMU and LXC templates from one cluster request' do
        resources = [
          { 'vmid' => 100, 'node' => 'pve1', 'type' => 'qemu', 'template' => 1, 'name' => 'qemu-template' },
          { 'vmid' => 101, 'node' => 'pve2', 'type' => 'lxc', 'template' => 1, 'name' => 'lxc-template' },
          { 'vmid' => 102, 'type' => 'qemu', 'template' => 0, 'name' => 'regular-vm' },
          { 'vmid' => 103, 'type' => 'lxc', 'name' => 'regular-container' },
        ]
        @client.expects(:list_cluster_resources).with(type: 'vm').once.returns(resources)

        images = @cr.available_images

        assert_equal ["#{@cr.id}_100", "#{@cr.id}_101"], images.map(&:id)
        assert_equal %w[qemu-template lxc-template], images.map(&:name)
      end

      it 'removes duplicates' do
        template = { 'vmid' => 100, 'type' => 'qemu', 'template' => 1, 'name' => 'vm-1' }
        @client.expects(:list_cluster_resources).with(type: 'vm').once.returns([template, template])

        assert_equal 1, @cr.available_images.length
      end

      it 'returns no images when the cluster has no templates' do
        @client.expects(:list_cluster_resources).with(type: 'vm').once.returns([])

        assert_empty @cr.available_images
      end

      it 'accepts a string template flag' do
        resources = [
          { 'vmid' => 100, 'type' => 'qemu', 'template' => '1', 'name' => 'vm-1' },
          { 'vmid' => 101, 'type' => 'qemu', 'template' => '0', 'name' => 'vm-2' },
        ]
        @client.expects(:list_cluster_resources).with(type: 'vm').once.returns(resources)

        assert_equal ['vm-1'], @cr.available_images.map(&:name)
      end
    end
  end
end
