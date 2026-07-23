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

    test 'supports refreshing the compute resource cache' do
      cr = FactoryBot.build_stubbed(:proxmox_cr)

      assert_respond_to cr, :refresh_cache
    end

    test '#refresh_cache invalidates cached metadata' do
      cr = FactoryBot.create(:proxmox_cr, caching_enabled: true)
      first_node = stub(node: 'node-1')
      refreshed_node = stub(node: 'node-2')
      cr.expects(:nodes).twice.returns([first_node], [refreshed_node])
      cr.expects(:pools).twice.returns([])
      cr.expects(:images).twice.returns([])
      cr.stubs(:storages).returns([])
      cr.stubs(:bridges).returns([])

      initial_metadata = cr.metadata

      assert_equal initial_metadata, cr.metadata
      assert cr.refresh_cache
      assert_equal [{ node: 'node-2' }], cr.metadata[:nodes]
    end

    test '#metadata loads fresh data when caching is disabled' do
      cr = FactoryBot.build_stubbed(:proxmox_cr, caching_enabled: false)
      first_node = stub(node: 'node-1')
      second_node = stub(node: 'node-2')
      cr.expects(:nodes).twice.returns([first_node], [second_node])
      cr.expects(:pools).twice.returns([])
      cr.expects(:images).twice.returns([])
      cr.stubs(:storages).returns([])
      cr.stubs(:bridges).returns([])

      assert_equal [{ node: 'node-1' }], cr.metadata[:nodes]
      assert_equal [{ node: 'node-2' }], cr.metadata[:nodes]
    end

    test '#metadata includes storages from every node' do
      cr, first_node, second_node = metadata_compute_resource
      cr.expects(:storages).with(first_node.node).returns([{ storage: 'local', node_id: first_node.node }])
      cr.expects(:storages).with(second_node.node).returns([{ storage: 'shared', node_id: second_node.node }])

      assert_equal ['local', 'shared'], cr.metadata[:storages].pluck(:storage)
    end

    test '#metadata includes bridges from every node' do
      cr, first_node, second_node = metadata_compute_resource
      cr.expects(:bridges).with(first_node.node).returns([{ iface: 'vmbr0', node_id: first_node.node }])
      cr.expects(:bridges).with(second_node.node).returns([{ iface: 'vmbr1', node_id: second_node.node }])

      assert_equal ['vmbr0', 'vmbr1'], cr.metadata[:bridges].pluck(:iface)
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

    test '#node' do
      node = mock('node')
      cr = FactoryBot.build_stubbed(:proxmox_cr)
      cr.stubs(:node).returns(node)
      assert_equal node, (as_admin { cr.node })
    end

    private

    def metadata_compute_resource
      cr = FactoryBot.build_stubbed(:proxmox_cr, caching_enabled: false)
      nodes = [stub(node: 'node-1'), stub(node: 'node-2')]
      cr.stubs(:nodes).returns(nodes)
      cr.stubs(:pools).returns([])
      cr.stubs(:storages).returns([])
      cr.stubs(:bridges).returns([])
      cr.stubs(:images).returns([])
      [cr, *nodes]
    end

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
