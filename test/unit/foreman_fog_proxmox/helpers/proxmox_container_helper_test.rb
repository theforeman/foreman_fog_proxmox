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
class ProxmoxContainerHelperTest < ActiveSupport::TestCase
  include ProxmoxContainerHelper
  include ProxmoxVmHelper

  describe 'parse' do

    setup { Fog.mock! }
    teardown { Fog.unmock! }

    let(:host) do 
      { 'vmid' => '100', 
        'name' =>  'test', 
        'type' =>  'lxc', 
        'node_id' => 'pve',
        'ostemplate_storage' => 'local',
        'ostemplate_file' => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
        'password' => 'proxmox01',
        'config_attributes' => { 
          'onboot' => '0', 
          'description' => '', 
          'memory' => '536870912', 
          'swap' => '536870912',
          'cores' => '1',
          'cpulimit' => '',
          'cpuunits' => '',
          'arch' => 'amd64',
          'ostype' => 'debian',
          'hostname' => '',
          'nameserver' => '',
          'searchdomain' => '',
          
        },
        'volumes_attributes' => {
          '0'=> { 'id' => 'rootfs', 'storage' => 'local-lvm', 'size' => '1073741824', 'cache' => '' },
          '1'=> { 'id' => 'mp0', 'storage' => 'local-lvm', 'size' => '1073741824', 'mp' => '/opt/path' }
        }, 
        'interfaces_attributes' => { 
          '0' => { 'id' => 'net0', 'name' => 'eth0', 'bridge' => 'vmbr0', 'ip' => 'dhcp', 'ip6' => 'dhcp', 'rate' => '' },
          '1' => { 'id' => 'net1', 'name' => 'eth1', 'bridge' => 'vmbr0', 'ip' => 'dhcp', 'ip6' => 'dhcp' } 
        } 
      }
    end

    let(:container) do 
      { 'vmid' => '100',
        :vmid => '100',  
        'name' =>  'test', 
        'type' =>  'lxc', 
        :type =>  'lxc', 
        'node_id' => 'pve',
        :node_id => 'pve',
        :memory => 536870912, 
        'templated' => 0, 
        :onboot => 0,
        :swap => 536870912,
        'cores' => '1',
        :arch => 'amd64',
        :ostype => 'debian',
        'ostemplate' => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
        'ostemplate_storage' => 'local',
        'ostemplate_file' => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
        'password' => 'proxmox01',
        :rootfs => 'local-lvm:1073741824',
        :mp0 => 'local-lvm:1073741824,mp=/opt/path',
        'net0' => 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp',
        'net1' => 'model=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp'
      }
    end

    let(:host_delete) do 
      { 'vmid' => '100', 
        'name' =>  'test', 
        'type' =>  'lxc', 
        'node_id' => 'pve',
        'volumes_attributes' => { '0' => { '_delete' => '1', 'device' => '0', 'storage' => 'local-lvm', 'size' => '1073741824', 'mp' => '/opt/path' }}, 
        'interfaces_attributes' => { '0' => { '_destroy' => '1', 'id' => 'net0', 'name' => 'eth0' } } 
      }
    end

    test '#memory' do       
      memory = parse_container_memory(host['config_attributes'])
      assert memory.has_key?(:memory)
      assert_equal 536870912, memory[:memory]
      assert memory.has_key?(:swap)
      assert_equal 536870912, memory[:swap]
    end   

    test '#cpu' do       
      cpu = parse_container_cpu(host['config_attributes'])
      assert cpu.has_key?(:cores)
      assert_equal 1, cpu[:cores]
      assert cpu.has_key?(:arch)
      assert_equal 'amd64', cpu[:arch]
    end    

    test '#ostemplate' do       
      ostemplate = parse_container_ostemplate(host)
      expected_ostemplate = { 
        :ostemplate =>  'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
        :ostemplate_storage =>  'local',
        :ostemplate_file =>  'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz'
       }
      assert_equal expected_ostemplate, ostemplate
    end   

    test '#vm host' do       
      vm = parse_container_vm(host)
      assert_equal 536870912, vm[:memory]
      assert_equal 'local-lvm:1073741824', vm[:rootfs]
      assert_equal 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp', vm[:net0]
      assert !vm.has_key?(:config)
      assert !vm.has_key?(:node)
      assert !vm.has_key?(:type)
    end   

    test '#vm container' do       
      vm = parse_container_vm(host)
      expected_vm = ActiveSupport::HashWithIndifferentAccess.new( 
        :vmid => '100', 
        :password => 'proxmox01', 
        :onboot => '0', 
        :ostype => 'debian', 
        :arch => 'amd64', 
        :cores => 1, 
        :memory => 536870912, 
        :swap => 536870912, 
        :ostemplate => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
        :ostemplate_file => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
        :ostemplate_storage => 'local',
        :net0 => 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp',
        :net1 => 'name=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp',
        :rootfs => 'local-lvm:1073741824', 
        :mp0 => 'local-lvm:1073741824,mp=/opt/path' )
      assert_equal expected_vm, vm
    end   

    test '#volume with rootfs 1Gb' do       
      volumes = parse_container_volumes(host['volumes_attributes'])
      assert !volumes.empty?
      assert_equal 2, volumes.size
      assert rootfs = volumes.first
      assert rootfs.has_key?(:rootfs)
      assert_equal 'local-lvm:1073741824', rootfs[:rootfs]
      assert mp0 = volumes[1]
      assert mp0.has_key?(:mp0)
      assert_equal 'local-lvm:1073741824,mp=/opt/path', mp0[:mp0]
    end    
    
    test '#interface with name eth0 and bridge' do       
      deletes = []
      nics = []    
      add_container_interface(host['interfaces_attributes']['0'], deletes, nics)
      assert 1, nics.length
      assert nics[0].has_key?(:net0)
      assert_equal 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp', nics[0][:net0]
    end
    
    test '#interface with name eth1 and bridge' do          
      deletes = []
      nics = []    
      add_container_interface(host['interfaces_attributes']['1'], deletes, nics)
      assert 1, nics.length
      assert nics[0].has_key?(:net1)
      assert_equal 'name=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp', nics[0][:net1]
    end
    
    test '#interface delete net0' do         
      deletes = []
      nics = []    
      add_container_interface(host_delete['interfaces_attributes']['0'], deletes, nics)
      assert nics.empty?
      assert_equal 1, deletes.length
      assert_equal 'net0', deletes[0]
    end
    
    test '#interfaces' do       
      interfaces_to_add, interfaces_to_delete = parse_container_interfaces(host['interfaces_attributes'])
      assert interfaces_to_delete.empty?
      assert_equal 2, interfaces_to_add.length
      assert interfaces_to_add.include?({ net0: 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp'})
      assert interfaces_to_add.include?({ net1: 'name=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp'})
    end

  end
end
end