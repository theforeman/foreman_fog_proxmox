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
require 'fog/compute/proxmox/models/server'
require 'fog/compute/proxmox/models/server_config'
require 'fog/compute/proxmox/models/interface'
require 'fog/compute/proxmox/models/interfaces'
require 'fog/compute/proxmox/models/disk'
require 'fog/compute/proxmox/models/disks'
require 'fog/compute/proxmox/models/snapshots'
require 'fog/compute/proxmox/models/tasks'

module ForemanFogProxmox
class ProxmoxVmHelperTest < ActiveSupport::TestCase
  include ProxmoxVmHelper

  let(:container) do 
    service = mock('service')
    service.stubs(:get_server_config).returns(nil)
    service.stubs(:list_tasks).returns([])
    Fog::Proxmox::Compute::Server.new(
    { 'vmid' => '100', 
      'hostname' =>  'test', 
      :type =>  'lxc', 
      :node_id => 'pve',
      :service => service,
      'templated' => '0', 
      'memory' => '536870912', 
      'swap' => '',
      'cores' => '1',
      'arch' => 'amd64',
      'ostype' => 'debian',
      'rootfs' => 'local-lvm:1073741824',
      'mp0' => 'local-lvm:1073741824', 
      'net0' => 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp',
      'net1' => 'name=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp'
    })
  end

  let(:server) do 
    service = mock('service')
    service.stubs(:get_server_config).returns(nil)
    service.stubs(:list_tasks).returns([])
    Fog::Proxmox::Compute::Server.new(
    { 'vmid' => '100', 
      'name' =>  'test', 
      :node_id => 'pve', 
      :service => service,
      :type => 'qemu',
      'templated' => '0', 
      'ide2' => 'local-lvm:iso/debian-netinst.iso,media=cdrom',
      'memory' => '536870912', 
      'min_memory' => '', 
      'ballon' => '', 
      'shares' => '', 
      'cpu_type' => 'kvm64', 
      'spectre' => '1', 
      'pcid' => '0', 
      'cores' => '1', 
      'sockets' => '1',
      'scsi0' => 'local-lvm:1073741824,cache=none', 
      'net0' => 'model=virtio,bridge=vmbr0',
      'net1'  => 'model=e1000,bridge=vmbr0'
    })
  end

  let(:host_server) do 
    { 'vmid' => '100', 
      'name' =>  'test', 
      'node_id' => 'pve',
      'type' => 'qemu',
      'config_attributes' => { 
        'memory' => '536870912', 
        'min_memory' => nil, 
        'ballon' => '', 
        'shares' => '', 
        'cpu_type' => 'kvm64', 
        'spectre' => '1', 
        'pcid' => '0', 
        'cores' => '1', 
        'sockets' => '1'
      },
      'volumes_attributes' => {
        '0'=> { 'controller' => 'scsi', 'device' => '0', 'storage' => 'local-lvm', 'size' => '1073741824', 'cache' => 'none' }
      }, 
      'interfaces_attributes' => { 
        '0' => { 'id' => 'net0', 'model' => 'virtio', 'bridge' => 'vmbr0', 'firewall' => '0', 'disconnect' => '0' },
        '1' => { 'id' => 'net1', 'model' => 'e1000', 'bridge' => 'vmbr0', 'firewall' => '0', 'disconnect' => '0' } 
      } 
    }
  end    
  
  let(:host_container) do 
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
        'swap' => '',
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
        '0'=> { 'id' => 'rootfs', 'storage' => 'local-lvm', 'size' => '1073741824' },
        '1'=> { 'id' => 'mp0', 'storage' => 'local-lvm', 'size' => '1073741824' }
      }, 
      'interfaces_attributes' => { 
        '0' => { 'id' => 'net0', 'name' => 'eth0', 'bridge' => 'vmbr0', 'ip' => 'dhcp', 'ip6' => 'dhcp' },
        '1' => { 'id' => 'net1', 'name' => 'eth1', 'bridge' => 'vmbr0', 'ip' => 'dhcp', 'ip6' => 'dhcp' } 
      } 
    }
  end

  describe 'object_to_config_hash' do

    setup { Fog.mock! }
    teardown { Fog.unmock! }

    it '#server qemu' do            
      config_hash = object_to_config_hash(server,'qemu')
      expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(server.config.attributes).reject { |key,_value| %w[templated ide2 scsi0 net0 net1].include? key }
      assert_equal expected_config_hash, config_hash['config_attributes']
    end  

    it '#server lxc' do       
      config_hash = object_to_config_hash(server,'lxc')
      assert config_hash.has_key?('config_attributes')
      expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(server.config.attributes).reject { |key,_value| %w[templated ide2 scsi0 net0 net1].include? key }
      assert_equal expected_config_hash, config_hash['config_attributes']
    end    

    it '#container qemu' do       
      config_hash = object_to_config_hash(container,'qemu')
      assert config_hash.has_key?('config_attributes')
      expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(container.config.attributes).reject { |key,_value| %w[templated rootfs mp0 net0 net1].include? key }
      assert_equal expected_config_hash, config_hash['config_attributes']
    end  

    it '#container lxc' do       
      config_hash = object_to_config_hash(container,'lxc')
      assert config_hash.has_key?('config_attributes')
      expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(container.config.attributes).reject { |key,_value| %w[templated rootfs mp0 net0 net1].include? key }
      assert_equal expected_config_hash, config_hash['config_attributes']
    end    
  end


  describe 'convert_sizes' do

    setup { Fog.mock! }
    teardown { Fog.unmock! }

    it '#server' do       
      convert_sizes(host_server)
      assert_equal '512', host_server['config_attributes']['memory']
      assert_equal '1', host_server['volumes_attributes']['0']['size']
    end  

    it '#container' do       
      convert_sizes(host_container)
      assert_equal '512', host_container['config_attributes']['memory']
      assert_equal '1', host_container['volumes_attributes']['0']['size']
    end  
  end

  describe 'convert_memory_size' do

    setup { Fog.mock! }
    teardown { Fog.unmock! }

    it '#server memory' do       
      convert_memory_size(host_server['config_attributes'],'memory')
      assert_equal '512', host_server['config_attributes']['memory']
    end  

    it '#server min_memory nil' do       
      convert_memory_size(host_server['config_attributes'],'min_memory')
      assert_nil host_server['config_attributes']['min_memory']
    end  

    it '#container memory' do       
      convert_memory_size(host_container['config_attributes'],'memory')
      assert_equal '512', host_container['config_attributes']['memory']
    end 

    it '#container swap empty' do       
      convert_memory_size(host_container['config_attributes'],'swap')
      assert host_container['config_attributes']['swap'].empty?
    end 
  end

  describe 'parse_type_and_vmid' do

    setup { Fog.mock! }
    teardown { Fog.unmock! }

    it "raises Foreman::Exception when the uuid does not match" do
      err = assert_raises Foreman::Exception do
        parse_type_and_vmid('100')
      end
      assert err.message.end_with?('Invalid uuid=[100].')
    end

    it '#server' do       
      type, vmid = parse_type_and_vmid('qemu_100')
      assert_equal 'qemu', type
      assert_equal '100', vmid
    end  

    it '#container' do       
      type, vmid = parse_type_and_vmid('lxc_100')
      assert_equal 'lxc', type
      assert_equal '100', vmid
    end  
  end

end
end