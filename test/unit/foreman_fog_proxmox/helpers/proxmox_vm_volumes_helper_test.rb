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
  class ProxmoxVmVolumesHelperTest < ActiveSupport::TestCase
    include ProxmoxVmVolumesHelper

    describe 'remove_deletes' do
      setup { Fog.mock! }
      teardown { Fog.unmock! }
      args = {
        'volumes_attributes' => {
          '0' => {
            '_delete' => '',
            'id' => 'scsi0',
            'volid' => 'local-lvm:vm-100-disk',
            'storage' => 'local-lvm',
            'storage_type' => 'hard_disk'
          }
        }
      }

      it '# server volumes' do
        remove_volume_keys(args)
        assert args.key?('volumes_attributes')
        assert args['volumes_attributes'].key?('0')
        assert_not args['volumes_attributes']['0'].key?('_delete')
        # assert_not args['volumes_attributes']['0'].key?('storage_type')
      end
    end
  end
end
