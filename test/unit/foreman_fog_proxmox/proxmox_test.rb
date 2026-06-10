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
  class ProxmoxTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxNodeMockFactory
    include ProxmoxServerMockFactory
    include ProxmoxContainerMockFactory
    include ProxmoxVMHelper

    should validate_presence_of(:url)
    should validate_presence_of(:user)
    should validate_presence_of(:password)
    should allow_value('root@pam').for(:user)
    should_not allow_value('root').for(:user)
    should_not allow_value('a').for(:url)
    should allow_values('http://foo.com', 'http://bar.com/baz').for(:url)

    test '#associated_host matches any NIC' do
      mac = 'ca:d0:e6:32:16:97'
      host = FactoryBot.create(:host, :mac => mac)
      cr = FactoryBot.build_stubbed(:proxmox_cr)
      vm = mock('vm', :mac => mac)
      assert_equal host, (as_admin { cr.associated_host(vm) })
    end

    test '#provided_attributes maps uuid to foreman_uuid' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)

      assert_equal :foreman_uuid, cr.provided_attributes[:uuid]
    end

    test '#update_required? detects added HDD attributes' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)
      old_attrs = hdd_compute_attrs(hdd_attrs('0'))
      new_attrs = hdd_compute_attrs(hdd_attrs('0').merge('1' => hdd_attributes('virtio1', 'virtio', '1')))

      assert cr.update_required?(old_attrs, new_attrs)
    end

    test '#update_required? detects removed HDD attributes' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)

      old_attrs = hdd_compute_attrs(
        hdd_attrs('0').merge('1' => hdd_attributes('virtio1', 'virtio', '1'))
      )

      new_attrs = hdd_compute_attrs(
        hdd_attrs('0').merge('1' => { '_delete' => '1' })
      )

      assert cr.update_required?(old_attrs, new_attrs)
    end

    test '#update_required? detects modified existing HDD attributes' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)
      old_attrs = hdd_compute_attrs(hdd_attrs('0'))
      new_attrs = hdd_compute_attrs(hdd_attrs('0').deep_merge('0' => { 'size' => '20' }))

      assert cr.update_required?(old_attrs, new_attrs)
    end

    test '#update_required? detects modified CPU flag' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)
      old_attrs = { 'config_attributes' => { 'spectre' => '0' } }
      new_attrs = { 'config_attributes' => { 'spectre' => '+1' } }

      assert cr.update_required?(old_attrs, new_attrs)
    end

    test '#update_required? detects modified network interface' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)
      old_attrs = { 'interfaces_attributes' => { '0' => { 'id' => 'net0', 'bridge' => 'vmbr0' } } }
      new_attrs = { 'interfaces_attributes' => { '0' => { 'id' => 'net0', 'bridge' => 'vmbr1' } } }

      assert cr.update_required?(old_attrs, new_attrs)
    end

    test '#update_required? detects added network interface' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)
      old_attrs = { 'interfaces_attributes' => { '0' => { 'id' => 'net0' } } }
      new_attrs = { 'interfaces_attributes' => { '0' => { 'id' => 'net0' }, '1' => { 'id' => 'net1' } } }

      assert cr.update_required?(old_attrs, new_attrs)
    end

    test 'supports compute resource cache refreshing' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)

      assert_respond_to cr, :refresh_cache
    end

    test '#node' do
      node = mock('node')
      cr = FactoryBot.build_stubbed(:proxmox_cr)
      cr.stubs(:node).returns(node)
      assert_equal node, (as_admin { cr.node })
    end

    test '#extract_attributes returns selected resource attributes' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)

      resource = OpenStruct.new(
        vmid: 101,
        name: 'template-101',
        ignored: 'ignored'
      )

      attributes = cr.send(:extract_attributes, resource, [:vmid, :name, :missing])

      assert_equal(
        {
          vmid: 101,
          name: 'template-101',
          missing: nil,
        },
        attributes
      )
    end

    private

    def hdd_compute_attrs(volumes_attrs)
      { 'volumes_attributes' => volumes_attrs }
    end

    def hdd_attrs(index)
      { index => hdd_attributes('scsi0', 'scsi', '0') }
    end

    def hdd_attributes(id, controller, device)
      {
        'id' => id,
        'storage_type' => 'hard_disk',
        'controller' => controller,
        'device' => device,
        'storage' => 'local-lvm',
        'size' => '10',
      }
    end
  end
end
