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
        @image.stubs(:node_id).returns('pve1')
        @clone = mock('vm')
        @cr.stubs(:find_vm_by_uuid).with(@cr.id.to_s + '_' + @vmid.to_s).returns(@clone)
      end

      it 'passes the target node to the clone call so image deployment works across hosts' do
        @image.expects(:clone).with(@vmid, { target: 'pve2' })

        assert_equal @clone, @cr.clone_from_image(@image, @vmid, target_node: 'pve2')
      end

      it 'omits the target for a same-node deploy so local-storage templates keep working' do
        @image.expects(:clone).with(@vmid, {})

        assert_equal @clone, @cr.clone_from_image(@image, @vmid, target_node: 'pve1')
      end

      it 'omits the target when no node is given' do
        @image.expects(:clone).with(@vmid, {})

        assert_equal @clone, @cr.clone_from_image(@image, @vmid)
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
  end
end
