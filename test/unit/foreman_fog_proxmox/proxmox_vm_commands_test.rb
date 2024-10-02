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
require 'factories/foreman_fog_proxmox/proxmox_node_mock_factory'
require 'factories/foreman_fog_proxmox/proxmox_server_mock_factory'
require 'factories/foreman_fog_proxmox/proxmox_container_mock_factory'
require 'active_support/core_ext/hash/indifferent_access'

module ForemanFogProxmox
  class ProxmoxVMCommandsServerTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVMHelper

    describe 'destroy_vm' do
      it 'handles situation when vm is not present' do
        cr = mock_cr_servers(ForemanFogProxmox::Proxmox.new, empty_servers)
        cr.expects(:find_vm_by_uuid).raises(ActiveRecord::RecordNotFound)
        assert cr.destroy_vm('abc')
      end
    end
  end
end
