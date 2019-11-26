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
  class ProxmoxVmCommandsServerTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers

    describe 'clone_from_image' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
        @args = { :name => 'name' }
        @image_id = 100
        @vmid = 101
        @image = mock('vm')
        @image.expects(:clone)
        @cr.stubs(:find_vm_by_uuid).with(@image_id).returns(@image)
        @clone = mock('vm')
      end
      it 'clones server from image' do
        @clone.expects(:update).with(:name => 'name')
        @clone.stubs(:container?).returns(false)
        @cr.stubs(:find_vm_by_uuid).with(@vmid).returns(@clone)
        @cr.clone_from_image(@image_id, @args, @vmid)
      end
      it 'clones container from image' do
        @clone.stubs(:container?).returns(true)
        @clone.expects(:update).with(:hostname => 'name')
        @cr.stubs(:find_vm_by_uuid).with(@vmid).returns(@clone)
        @cr.clone_from_image(@image_id, @args, @vmid)
      end
    end
  end
end
