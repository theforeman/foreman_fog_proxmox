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
require 'active_support/core_ext/hash/indifferent_access'

module ForemanFogProxmox
  class ProxmoxVmCommandsServerCreateTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxVmHelper

    describe 'create_vm' do
      it 'raises Foreman::Exception when vmid is invalid' do
        args = { vmid: '100' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(false)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        err = assert_raises Foreman::Exception do
          cr.create_vm(args)
        end
        assert err.message.end_with?('invalid vmid=100')
      end

      it 'creates server without bootstart' do
        args = { vmid: '100', type: 'qemu', config_attributes: { onboot: '0' } }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:convert_sizes).with(args)
        cr.stubs(:parse_server_vm).with(args).returns(args)
        servers.stubs(:create).with(args)
        vm = mock('vm')
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.create_vm(args)
      end

      it 'creates server with bootstart' do
        args = { vmid: '100', type: 'qemu', config_attributes: { onboot: '1' } }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:convert_sizes).with(args)
        cr.stubs(:parse_server_vm).with(args).returns(args)
        vm = mock('vm')
        servers.stubs(:create).with(args).returns(vm)
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.stubs(:start_on_boot).with(vm, args).returns(vm)
        cr.create_vm(args)
      end

      it 'clones server' do
        args = { vmid: '100', type: 'qemu', image_id: '999', name: 'name' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:convert_sizes).with(args)
        cr.stubs(:parse_server_vm).with(args).returns(args)
        servers.stubs(:create).with(args)
        image = mock('image')
        clone = mock('clone')
        image.stubs(:clone).with(100)
        servers.stubs(:get).with(100).returns(clone)
        servers.stubs(:get).with('999').returns(image)
        clone.stubs(:update).with(name: 'name')
        vm = mock('vm')
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.create_vm(args)
      end
    end
  end
end
