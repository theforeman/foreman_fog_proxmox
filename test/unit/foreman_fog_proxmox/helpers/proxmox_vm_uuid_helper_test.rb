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
  class ProxmoxVMUuidHelperTest < ActiveSupport::TestCase
    include ProxmoxVMUuidHelper

    describe 'extract_vmid' do
      setup { Fog.mock! }
      teardown { Fog.unmock! }

      it '#uuid=1_100 returns 100' do
        assert_equal '100', extract_vmid('1_100')
      end
      it '#uuid=pve_100 returns ' do
        assert_equal '', extract_vmid('pve_100')
      end
    end
  end
end
