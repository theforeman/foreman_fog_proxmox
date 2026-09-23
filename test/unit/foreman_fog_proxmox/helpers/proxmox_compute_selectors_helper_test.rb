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
  class ProxmoxComputeSelectorsHelperTest < ActiveSupport::TestCase
    include ProxmoxComputeSelectorsHelper

    describe 'proxmox_archs_map' do
      it 'returns the supported LXC architectures' do
        expected = [
          ['amd64', 'amd64 (64-bit x86)'],
          ['i386', 'i386 (32-bit x86)'],
          ['arm64', 'arm64 (64-bit ARM)'],
          ['armhf', 'armhf (32-bit ARM)'],
        ]
        actual = proxmox_archs_map.map { |arch| [arch.id, arch.name] }

        assert_equal expected, actual
      end
    end
  end
end
