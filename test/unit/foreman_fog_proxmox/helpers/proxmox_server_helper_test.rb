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
  class ProxmoxServerHelperTest < ActiveSupport::TestCase
    include ProxmoxVmHelper

    describe 'parse' do
      setup { Fog.mock! }
      teardown { Fog.unmock! }

      let(:type) do
        'qemu'
      end

      let(:host_form) do
        { 'vmid' => '100',
          'name' => 'toto-tata.pve',
          'node_id' => 'proxmox',
          'type' => 'qemu',
          'config_attributes' => {
            'name' => 'toto-tata.pve',
            'memory' => '536870912',
            'balloon' => '268435456',
            'shares' => '5',
            'cpu_type' => 'kvm64',
            'spectre' => '+1',
            'pcid' => '0',
            'cores' => '1',
            'sockets' => '1',
          },
          'volumes_attributes' => {
            '0' => { 'id' => 'scsi0', 'storage_type' => 'hard_disk', 'controller' => 'scsi', 'device' => '0',
                     'storage' => 'local-lvm', 'size' => '1073741824', 'cache' => 'none' },
            '1' => { 'id' => 'virtio0', 'storage_type' => 'hard_disk', 'controller' => 'virtio', 'device' => '0',
                     'storage' => 'local-lvm', 'size' => '1073741824', 'cache' => 'none' },
            '2' => { 'id' => 'ide2', 'storage_type' => 'cdrom', 'controller' => 'ide', 'device' => '2',
                     'storage' => 'local-lvm', 'cdrom' => 'none' },
          },
          'interfaces_attributes' => {
            '0' => { 'id' => 'net0',
                     'compute_attributes' => { 'model' => 'virtio', 'bridge' => 'vmbr0', 'firewall' => '0', 'link_down' => '0',
                                               'rate' => nil } },
            '1' => { 'id' => 'net1',
                     'compute_attributes' => { 'model' => 'e1000', 'bridge' => 'vmbr0', 'firewall' => '0',
                                               'link_down' => '0' } },
          } }
      end

      let(:host_delete) do
        { 'vmid' => '100',
          'node_id' => 'proxmox',
          'name' => 'test',
          'type' => 'qemu',
          'volumes_attributes' => {
            '0' => { '_delete' => '1', 'storage_type' => 'hard_disk', 'controller' => 'scsi', 'device' => '0',
                     'storage' => 'local-lvm', 'size' => '1073741824' },
            '1' => { '_delete' => '', 'storage_type' => 'cdrom', 'controller' => 'ide', 'device' => '2',
                     'storage' => 'local-lvm', 'volid' => 'local-lvm:iso/debian-netinst.iso', 'cdrom' => 'image' },
          },
          'interfaces_attributes' => { '0' => { '_delete' => '1', 'id' => 'net0',
                                                'compute_attributes' => { 'model' => 'virtio' } } } }
      end

      test '#memory' do
        memory = parse_typed_memory(host_form['config_attributes'], type)
        assert memory.key?(:memory)
        assert_equal 536_870_912, memory[:memory]
      end

      test '#cpu' do
        cpu = parse_typed_cpu(host_form['config_attributes'], type)
        assert cpu.key?(:cpu)
        assert_equal 'cputype=kvm64,flags=+spec-ctrl', cpu[:cpu]
      end

      test '#cdrom none' do
        cdrom = parse_server_cdrom(host_form['volumes_attributes']['2'])
        assert cdrom.key?(:id)
        assert_equal 'ide2', cdrom[:id]
        assert cdrom.key?(:volid)
        assert_equal 'none', cdrom[:volid]
        assert cdrom.key?(:media)
        assert_equal 'cdrom', cdrom[:media]
      end

      test '#cdrom image' do
        cdrom = parse_server_cdrom(host_delete['volumes_attributes']['1'])
        assert cdrom.key?(:id)
        assert_equal 'ide2', cdrom[:id]
        assert cdrom.key?(:volid)
        assert_equal 'local-lvm:iso/debian-netinst.iso', cdrom[:volid]
        assert cdrom.key?(:media)
        assert_equal 'cdrom', cdrom[:media]
      end

      test '#vm' do
        vm = parse_typed_vm(host_form, type)
        assert_equal '1', vm['cores']
        assert_equal '1', vm['sockets']
        assert_equal 'cputype=kvm64,flags=+spec-ctrl', vm[:cpu]
        assert_equal 536_870_912, vm[:memory]
        assert_equal 268_435_456, vm[:balloon]
        assert_equal 5, vm[:shares]
        assert_equal 'local-lvm:1073741824,cache=none', vm[:scsi0]
        assert_equal 'model=virtio,bridge=vmbr0,firewall=0,link_down=0', vm[:net0]
        assert_equal 'toto-tata.pve', vm[:name]
        assert_not vm.key?(:config)
        assert_not vm.key?(:node)
      end

      test '#volume with scsi 1Gb' do
        volumes = parse_typed_volumes(host_form['volumes_attributes'], type)
        assert_not volumes.empty?
        assert volumes.size, 3
        scsi0 = (volumes.select { |volume| volume.key?(:scsi0) }).first
        assert_equal 'local-lvm:1073741824,cache=none', scsi0[:scsi0]
      end

      test '#volume with virtio 1Gb' do
        volumes = parse_typed_volumes(host_form['volumes_attributes'], type)
        assert_not volumes.empty?
        assert volumes.size, 3
        virtio0 = (volumes.select { |volume| volume.key?(:virtio0) }).first
        assert_equal 'local-lvm:1073741824,cache=none', virtio0[:virtio0]
      end

      test '#interface with model virtio and bridge' do
        interfaces_to_delete = []
        interfaces_to_add = []
        add_or_delete_typed_interface(host_form['interfaces_attributes']['0'], interfaces_to_delete, interfaces_to_add,
          type)
        assert_empty interfaces_to_delete
        assert_equal 1, interfaces_to_add.length
        assert interfaces_to_add[0].key?(:net0)
        assert_equal 'model=virtio,bridge=vmbr0,firewall=0,link_down=0', interfaces_to_add[0][:net0]
      end

      test '#interface with model e1000 and bridge' do
        interfaces_to_delete = []
        interfaces_to_add = []
        add_or_delete_typed_interface(host_form['interfaces_attributes']['1'], interfaces_to_delete, interfaces_to_add,
          type)
        assert_empty interfaces_to_delete
        assert_equal 1, interfaces_to_add.length
        assert interfaces_to_add[0].key?(:net1)
        assert_equal 'model=e1000,bridge=vmbr0,firewall=0,link_down=0', interfaces_to_add[0][:net1]
      end

      test '#interface delete net0' do
        interfaces_to_delete = []
        interfaces_to_add = []
        add_or_delete_typed_interface(host_delete['interfaces_attributes']['0'], interfaces_to_delete,
          interfaces_to_add, type)
        assert_empty interfaces_to_add
        assert_equal 1, interfaces_to_delete.length
        assert_equal 'net0', interfaces_to_delete[0]
      end

      test '#interfaces' do
        interfaces_to_add, interfaces_to_delete = parse_typed_interfaces(host_form, type)
        assert_empty interfaces_to_delete
        assert_equal 2, interfaces_to_add.length
        assert_includes interfaces_to_add, { net0: 'model=virtio,bridge=vmbr0,firewall=0,link_down=0' }
        assert_includes interfaces_to_add, { net1: 'model=e1000,bridge=vmbr0,firewall=0,link_down=0' }
      end
    end
  end
end
