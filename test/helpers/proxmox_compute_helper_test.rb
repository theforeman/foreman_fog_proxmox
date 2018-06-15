# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanProxmox.

# ForemanProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanProxmox. If not, see <http://www.gnu.org/licenses/>.

require 'test_plugin_helper'

class ProxmoxComputeHelperTest < ActiveSupport::TestCase
  include ProxmoxComputeHelper

  describe 'parse' do

    setup { Fog.mock! }
    teardown { Fog.unmock! }

    let(:host) do 
      { 'vmid' => 100, 
        'name' =>  'test', 
        'node' => 'pve',
        'config' => { 
          'memory' => '512', 
          'min_memory' => '', 
          'ballon' => '', 
          'shares' => '', 
          'cpu_type' => 'kvm64', 
          'spectre' => '1', 
          'pcid' => '0', 
          'cores' => '1', 
          'sockets' => '1'
        },
        'volumes' => { 'bus' => 'scsi', 'device' => '0', 'storage' => 'local-lvm', 'size' => '1', 'cache' => 'none' }, 
        'interfaces_attributes' => { 
          '0' => { 'id' => 'net0', 'model' => 'virtio', 'bridge' => 'vmbr0' },
          '1' => { 'id' => 'net1', 'model' => 'e1000', 'bridge' => 'vmbr0' } 
        } 
      }
    end

    let(:host_delete) do 
      { 'vmid' => 100, 
        'name' =>  'test', 
        'volumes' => { '_delete' => '1', 'bus' => 'scsi', 'device' => '0', 'storage' => 'local-lvm', 'size' => '1' }, 
        'interfaces_attributes' => { '0' => { '_delete' => '1', 'id' => 'net0', 'model' => 'virtio' } } 
      }
    end

    test '#memory' do       
      memory = parse_memory(host['config'])
      assert memory.has_key?(:memory)
      assert_equal memory[:memory], 512
    end   

    test '#cpu' do       
      cpu = parse_cpu(host['config'])
      assert cpu.has_key?(:cpu)
      assert_equal cpu[:cpu], 'cputype=kvm64,flags=+spec-ctrl'
    end   

    test '#vm' do       
      vm = parse_vm(host)
      assert_equal vm['cores'], '1'
      assert_equal vm['sockets'], '1'
      assert_equal vm[:cpu], 'cputype=kvm64,flags=+spec-ctrl'
      assert_equal vm[:memory], 512
      assert_equal vm[:scsi0], 'local-lvm:1,cache=none'
      assert_equal vm[:net0], 'model=virtio,bridge=vmbr0'
      assert !vm.has_key?(:config)
      assert !vm.has_key?(:node)
    end   

    test '#volume with scsi 1Gb' do       
      volume = parse_volume(host['volumes'])
      assert volume.has_key?(:scsi0)
      assert_equal volume[:scsi0], 'local-lvm:1,cache=none'
    end    
    
    test '#volume delete scsi0' do       
      volume = parse_volume(host_delete['volumes'])
      assert volume.has_key?(:delete)
      assert_match(/(net0,){0,1}scsi0(,net0){0,1}/, volume[:delete])
      assert_equal volume.length, 1
    end
    
    test '#interface with model virtio and bridge' do       
      interface = parse_interface(host['interfaces_attributes']['0'].merge(device: '0'))
      assert interface.has_key?(:net0)
      assert_equal interface[:net0], 'model=virtio,bridge=vmbr0'
    end
    
    test '#interface with model e1000 and bridge' do       
      interface = parse_interface(host['interfaces_attributes']['1'].merge(device: '1'))
      assert interface.has_key?(:net1)
      assert_equal interface[:net1], 'model=e1000,bridge=vmbr0'
    end
    
    test '#interface delete net0' do       
      interface = parse_interface(host_delete['interfaces_attributes']['0'].merge(device: '0'))
      assert interface.has_key?(:delete)
      assert_match(/(scsi0,){0,1}net0(,scsi0){0,1}/, interface[:delete])
      assert_equal interface.length, 1
    end
    
    test '#interfaces' do       
      interfaces = parse_interfaces(host['interfaces_attributes'])
      assert !interfaces.empty?
      assert_equal interfaces.length, 2
      assert interfaces.include?({ net0: 'model=virtio,bridge=vmbr0'})
      assert interfaces.include?({ net1: 'model=e1000,bridge=vmbr0'})
    end

  end
end
