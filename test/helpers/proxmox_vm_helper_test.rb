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
require 'fog/compute/proxmox/models/container'
require 'fog/compute/proxmox/models/container_config'
require 'fog/compute/proxmox/models/interface'
require 'fog/compute/proxmox/models/interfaces'
require 'fog/compute/proxmox/models/disk'
require 'fog/compute/proxmox/models/disks'

class ProxmoxVmHelperTest < ActiveSupport::TestCase
  include ProxmoxVmHelper

  let(:container) do 
    Fog::Compute::Proxmox::Container.new(
    { 'vmid' => '100', 
      'hostname' =>  'test', 
      'type' =>  'lxc', 
      'node' => 'pve',
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
    Fog::Compute::Proxmox::Server.new(
    { 'vmid' => '100', 
      'name' =>  'test', 
      'node' => 'pve', 
      'type' => 'qemu',
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
      'node' => 'pve',
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
      'node' => 'pve',
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

    test '#server qemu' do       
      config_hash = object_to_config_hash(server,'qemu')
      expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(server.config.attributes).reject { |key,_value| %w[templated node type ide2 scsi0 net0 net1].include? key }
      assert_equal expected_config_hash, config_hash['config_attributes']
    end  

    test '#server lxc' do       
      config_hash = object_to_config_hash(server,'lxc')
      assert config_hash.has_key?('config_attributes')
      expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(server.config.attributes).reject { |key,_value| %w[templated node type ide2 scsi0 net0 net1].include? key }
      assert_equal expected_config_hash, config_hash['config_attributes']
    end    

    test '#container qemu' do       
      config_hash = object_to_config_hash(container,'qemu')
      assert config_hash.has_key?('config_attributes')
      expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(container.config.attributes).reject { |key,_value| %w[templated node type rootfs mp0 net0 net1].include? key }
      assert_equal expected_config_hash, config_hash['config_attributes']
    end  

    test '#container lxc' do       
      config_hash = object_to_config_hash(container,'lxc')
      assert config_hash.has_key?('config_attributes')
      expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(container.config.attributes).reject { |key,_value| %w[templated node type rootfs mp0 net0 net1].include? key }
      assert_equal expected_config_hash, config_hash['config_attributes']
    end    
  end


  describe 'convert_sizes' do

    setup { Fog.mock! }
    teardown { Fog.unmock! }

    test '#server' do       
      convert_sizes(host_server)
      assert_equal '512', host_server['config_attributes']['memory']
      assert_equal '1', host_server['volumes_attributes']['0']['size']
    end  

    test '#container' do       
      convert_sizes(host_container)
      assert_equal '512', host_container['config_attributes']['memory']
      assert_equal '1', host_container['volumes_attributes']['0']['size']
    end  
  end

  describe 'convert_memory_size' do

    setup { Fog.mock! }
    teardown { Fog.unmock! }

    test '#server' do       
      convert_memory_size(host_server['config_attributes'],'memory')
      assert_equal '512', host_server['config_attributes']['memory']
    end  

    test '#container' do       
      convert_memory_size(host_container['config_attributes'],'memory')
      assert_equal '512', host_container['config_attributes']['memory']
    end 
  end

end
