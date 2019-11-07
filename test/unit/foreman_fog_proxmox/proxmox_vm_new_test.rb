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
  class ProxmoxVmNewTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVmHelper

    describe 'new_vm' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'new server with attr empty' do
        attr = {}
        vm = mock('vm')
        config = mock('config')
        config.stubs(:inspect).returns('config')
        vm.stubs(:config).returns(config)
        @cr.stubs(:new_server_vm).with(attr).returns(vm)
        assert_equal vm, @cr.new_vm(attr)
      end

      it 'new server with attr not empty' do
        attr = { 'type' => 'qemu' }
        vm = mock('vm')
        config = mock('config')
        config.stubs(:inspect).returns('config')
        vm.stubs(:config).returns(config)
        @cr.stubs(:new_server_vm).with(attr).returns(vm)
        assert_equal vm, @cr.new_vm(attr)
      end

      it 'new container with attr not empty' do
        attr = { 'type' => 'lxc' }
        vm = mock('vm')
        config = mock('config')
        config.stubs(:inspect).returns('config')
        vm.stubs(:config).returns(config)
        @cr.stubs(:new_container_vm).with(attr).returns(vm)
        assert_equal vm, @cr.new_vm(attr)
      end
    end
  end
end
