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
require 'active_support/core_ext/hash/indifferent_access'

module ForemanFogProxmox
  class ProxmoxVolumesTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxVolumes

    describe 'volume_exists?' do
      setup { Fog.mock! }
      teardown { Fog.unmock! }

      it '# returns true' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns('1')
        disk.stubs(:hard_disk?).returns(true)
        disk.stubs(:cdrom?).returns(false)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('virti0')
        disk.stubs(:attributes).returns(id: 'virti0', storage: 'local-lvm', size: 1, volid: 'local-lvm:vm-100-disk-0')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '1')
        vm = mock('vm')
        vm.stubs(:identity).returns(uuid)
        vm.stubs(:attributes).returns('' => '')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('pve')
        volume_attributes = { '_delete' => '', 'id' => 'virti0', 'size' => '1', 'volid' => 'local-lvm:vm-100-disk-0' }.with_indifferent_access
        assert volume_exists?(vm, volume_attributes)
      end

      it '# returns false' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns('1')
        disk.stubs(:hard_disk?).returns(true)
        disk.stubs(:cdrom?).returns(false)
        disk.stubs(:has_volume?).returns(true)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('virti0')
        disk.stubs(:attributes).returns(id: 'virti0', storage: 'local-lvm', size: '1', volid: 'local-lvm:vm-100-disk-0')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '1')
        vm = mock('vm')
        vm.stubs(:identity).returns(uuid)
        vm.stubs(:attributes).returns('' => '')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('pve')
        volume_attributes = { '_delete' => '', 'id' => 'virti0', 'size' => '1', 'volid' => '' }.with_indifferent_access
        assert_not volume_exists?(vm, volume_attributes)
      end

      it '# returns false' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns('1')
        disk.stubs(:hard_disk?).returns(true)
        disk.stubs(:cdrom?).returns(false)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('virti0')
        disk.stubs(:attributes).returns(id: 'virti0', storage: 'local-lvm', size: 1, volid: 'local-lvm:vm-100-disk-0')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '1')
        vm = mock('vm')
        vm.stubs(:identity).returns(uuid)
        vm.stubs(:attributes).returns('' => '')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        vm.stubs(:node_id).returns('pve')
        volume_attributes = { '_delete' => '', 'id' => 'scsi0', 'size' => '1', 'volid' => '' }.with_indifferent_access
        assert_not volume_exists?(vm, volume_attributes)
      end
    end
  end
end
