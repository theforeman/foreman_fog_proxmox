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
        @image_id = @cr.id.to_s + '_' + 100.to_s
        @vmid = 101
        @image = mock('vm')
        @image.expects(:clone)
        @cr.stubs(:find_vm_by_uuid).with(@image_id).returns(@image)
        @clone = mock('vm')
        @image_vmid = @cr.id.to_s + '_' + @vmid.to_s
      end
      it 'clones server from image' do
        @clone.stubs(:container?).returns(false)
        @cr.stubs(:find_vm_by_uuid).with(@image_vmid).returns(@clone)
        @cr.clone_from_image(@image_id, @vmid)
      end
      it 'clones container from image' do
        @clone.stubs(:container?).returns(true)
        @cr.stubs(:find_vm_by_uuid).with(@image_vmid).returns(@clone)
        @cr.clone_from_image(@image_id, @vmid)
      end
    end

    describe 'update_boot_order' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
        @image_vmid = @cr.id.to_s + '_' + 101.to_s
      end

      it 'returns the boot order for image template with multiple disks' do
        image = mock('vm')
        image.stubs(:disks).returns(['scsi0:local-lvm:vm-100-disk-0,size=8G',
                                     'virtio1:local-lvm:vm-100-disk-1,size=16G',
                                     'ide2:local:cloudinit,media=cdrom'])
        @cr.stubs(:find_vm_by_uuid).with(@image_vmid).returns(image)

        assert_equal({ boot: 'order=scsi0;virtio1;ide2' }, @cr.update_boot_order(@image_vmid))
      end
    end
  end
end
