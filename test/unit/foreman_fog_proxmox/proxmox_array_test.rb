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

require 'foreman_fog_proxmox/proxmox_array'

module ForemanFogProxmox
    class ProxmoxArrayTest < ActiveSupport::TestCase
        describe 'to_s' do
            it '#[net0,net1] returns net0,net1' do            
                assert_equal 'net0,net1', ForemanFogProxmox::ProxmoxArray.to_s(['net0','net1'])
            end  
        end
    end
end