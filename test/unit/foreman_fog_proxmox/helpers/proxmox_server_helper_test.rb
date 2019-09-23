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
    include ProxmoxServerHelper
    include ProxmoxVmHelper

    describe 'parse' do
      setup { Fog.mock! }
      teardown { Fog.unmock! }

      let(:host) do
        { 'vmid' => '100',
          'name' => 'test',
          'node_id' => 'pve',
          'type' => 'qemu',
          'config_attributes' => {
            'memory' => '536870912',
            'min_memory' => '',
            'ballon' => '',
            'shares' => '',
            'cpu_type' => 'kvm64',
            'spectre' => '1',
            'pcid' => '0',
            'cores' => '1',
            'sockets' => '1'
          },
          'volumes_attributes' => {
            '0' => { 'controller' => 'scsi', 'device' => '0', 'storage' => 'local-lvm', 'size' => '1073741824', 'cache' => 'none' },
            '1' => { 'controller' => 'virtio', 'device' => '0', 'storage' => 'local-lvm', 'size' => '1073741824', 'cache' => 'none' }
          },
          'interfaces_attributes' => {
            '0' => { 'id' => 'net0', 'model' => 'virtio', 'bridge' => 'vmbr0', 'firewall' => '0', 'link_down' => '0', 'rate' => nil },
            '1' => { 'id' => 'net1', 'model' => 'e1000', 'bridge' => 'vmbr0', 'firewall' => '0', 'link_down' => '0' }
          } }
      end

      let(:host_delete) do
        { 'vmid' => '100',
          'name' => 'test',
          'type' => 'qemu',
          'cdrom' => 'image',
          'cdrom_iso' => 'local-lvm:iso/debian-netinst.iso',
          'volumes_attributes' => { '0' => { '_delete' => '1', 'controller' => 'scsi', 'device' => '0', 'storage' => 'local-lvm', 'size' => '1073741824' } },
          'interfaces_attributes' => { '0' => { '_delete' => '1', 'id' => 'net0', 'model' => 'virtio' } } }
      end

      test '#memory' do
        memory = parse_server_memory(host['config_attributes'])
        assert memory.key?(:memory)
        assert_equal 536_870_912, memory[:memory]
      end

      test '#cpu' do
        cpu = parse_server_cpu(host['config_attributes'])
        assert cpu.key?(:cpu)
        assert_equal 'cputype=kvm64,flags=+spec-ctrl', cpu[:cpu]
      end

      test '#vm' do
        vm = parse_server_vm(host)
        assert_equal '1', vm['cores']
        assert_equal '1', vm['sockets']
        assert_equal 'cputype=kvm64,flags=+spec-ctrl', vm[:cpu]
        assert_equal 536_870_912, vm[:memory]
        assert_equal 'local-lvm:1073741824,cache=none', vm[:scsi0]
        assert_equal 'model=virtio,bridge=vmbr0,firewall=0,link_down=0', vm[:net0]
        assert_not vm.key?(:config)
        assert_not vm.key?(:node)
      end

      test '#volume with scsi 1Gb' do
        volumes = parse_server_volumes(host['volumes_attributes'])
        assert_not volumes.empty?
        assert volumes.size, 2
        assert volume = volumes.first
        assert volume.key?(:scsi0)
        assert_equal 'local-lvm:1073741824,cache=none', volume[:scsi0]
      end

      test '#volume with virtio 1Gb' do
        volumes = parse_server_volumes(host['volumes_attributes'])
        assert_not volumes.empty?
        assert volumes.size, 2
        assert volume = volumes[1]
        assert volume.key?(:virtio0)
        assert_equal 'local-lvm:1073741824,cache=none', volume[:virtio0]
      end

      test '#interface with model virtio and bridge' do
        interfaces_to_delete = []
        interfaces_to_add = []
        add_server_interface(host['interfaces_attributes']['0'], interfaces_to_delete, interfaces_to_add)
        assert interfaces_to_delete.empty?
        assert_equal 1, interfaces_to_add.length
        assert interfaces_to_add[0].key?(:net0)
        assert_equal 'model=virtio,bridge=vmbr0,firewall=0,link_down=0', interfaces_to_add[0][:net0]
      end

      test '#interface with model e1000 and bridge' do
        interfaces_to_delete = []
        interfaces_to_add = []
        interface = add_server_interface(host['interfaces_attributes']['1'], interfaces_to_delete, interfaces_to_add)
        assert interfaces_to_delete.empty?
        assert_equal 1, interfaces_to_add.length
        assert interfaces_to_add[0].key?(:net1)
        assert_equal 'model=e1000,bridge=vmbr0,firewall=0,link_down=0', interfaces_to_add[0][:net1]
      end

      test '#interface delete net0' do
        interfaces_to_delete = []
        interfaces_to_add = []
        add_server_interface(host_delete['interfaces_attributes']['0'], interfaces_to_delete, interfaces_to_add)
        assert interfaces_to_add.empty?
        assert_equal 1, interfaces_to_delete.length
        assert_equal 'net0', interfaces_to_delete[0]
      end

      test '#interfaces' do
        interfaces_to_add, interfaces_to_delete = parse_server_interfaces(host['interfaces_attributes'])
        assert interfaces_to_delete.empty?
        assert_equal 2, interfaces_to_add.length
        assert interfaces_to_add.include?(net0: 'model=virtio,bridge=vmbr0,firewall=0,link_down=0')
        assert interfaces_to_add.include?(net1: 'model=e1000,bridge=vmbr0,firewall=0,link_down=0')
      end
    end
  end
end
