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
require 'fog/proxmox/compute/models/server'
require 'fog/proxmox/compute/models/server_config'
require 'fog/proxmox/compute/models/interface'
require 'fog/proxmox/compute/models/interfaces'
require 'fog/proxmox/compute/models/disk'
require 'fog/proxmox/compute/models/disks'
require 'fog/proxmox/compute/models/snapshots'
require 'fog/proxmox/compute/models/tasks'

module ForemanFogProxmox
  class ProxmoxVmHelperTest < ActiveSupport::TestCase
    include ProxmoxVmHelper

    let(:container) do
      service = mock('service')
      service.stubs(:get_server_config).returns(nil)
      service.stubs(:list_tasks).returns([])
      Fog::Proxmox::Compute::Server.new(
        'vmid' => '100',
        'hostname' => 'test',
        :type => 'lxc',
        :node_id => 'proxmox',
        :service => service,
        'templated' => '0',
        'memory' => '512',
        'swap' => '',
        'cores' => '1',
        'arch' => 'amd64',
        'ostype' => 'debian',
        'rootfs' => 'local-lvm:10',
        'mp0' => 'local-lvm:10',
        'net0' => 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp',
        'net1' => 'name=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp'
      )
    end

    let(:server) do
      service = mock('service')
      service.stubs(:get_server_config).returns(nil)
      service.stubs(:list_tasks).returns([])
      Fog::Proxmox::Compute::Server.new(
        'vmid' => '100',
        'name' => 'test',
        :node_id => 'proxmox',
        :service => service,
        :type => 'qemu',
        'templated' => '0',
        'ide2' => 'local-lvm:iso/debian-netinst.iso,media=cdrom',
        'memory' => '1024',
        'ballon' => '',
        'shares' => '',
        'cpu_type' => 'kvm64',
        'spectre' => '1',
        'pcid' => '0',
        'cores' => '1',
        'sockets' => '1',
        'scsi0' => 'local-lvm:10,cache=none',
        'net0' => 'model=virtio,bridge=vmbr0',
        'net1' => 'model=e1000,bridge=vmbr0'
      )
    end

    let(:host_server) do
      { 'vmid' => '100',
        'name' => 'test',
        'node_id' => 'proxmox',
        'type' => 'qemu',
        'config_attributes' => {
          'memory' => '1024',
          'balloon' => '512',
          'shares' => '512',
          'cpu_type' => 'kvm64',
          'spectre' => '1',
          'pcid' => '0',
          'cores' => '1',
          'sockets' => '1'
        },
        'volumes_attributes' => {
          '0' => { 'controller' => 'scsi', 'device' => '0', 'storage' => 'local-lvm', 'size' => '10', 'cache' => 'none' }
        },
        'interfaces_attributes' => {
          '0' => { 'id' => 'net0', 'model' => 'virtio', 'bridge' => 'vmbr0', 'firewall' => '0', 'disconnect' => '0' },
          '1' => { 'id' => 'net1', 'model' => 'e1000', 'bridge' => 'vmbr0', 'firewall' => '0', 'disconnect' => '0' }
        } }
    end

    let(:host_container) do
      { 'vmid' => '100',
        'name' => 'test',
        'type' => 'lxc',
        'node_id' => 'proxmox',
        'ostemplate_storage' => 'local',
        'ostemplate_file' => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
        'password' => 'proxmox01',
        'config_attributes' => {
          'onboot' => '0',
          'description' => '',
          'memory' => '1024',
          'swap' => '512',
          'cores' => '1',
          'cpulimit' => '',
          'cpuunits' => '',
          'arch' => 'amd64',
          'ostype' => 'debian',
          'hostname' => '',
          'nameserver' => '',
          'searchdomain' => ''

        },
        'volumes_attributes' => {
          '0' => { 'id' => 'rootfs', 'storage' => 'local-lvm', 'size' => '10' },
          '1' => { 'id' => 'mp0', 'storage' => 'local-lvm', 'size' => '10' }
        },
        'interfaces_attributes' => {
          '0' => { 'id' => 'net0', 'name' => 'eth0', 'bridge' => 'vmbr0', 'ip' => 'dhcp', 'ip6' => 'dhcp' },
          '1' => { 'id' => 'net1', 'name' => 'eth1', 'bridge' => 'vmbr0', 'ip' => 'dhcp', 'ip6' => 'dhcp' }
        } }
    end

    describe 'object_to_config_hash' do
      setup { Fog.mock! }
      teardown { Fog.unmock! }
      excluded_qemu_keys = ['templated', 'ide2', 'scsi0', 'net0', 'net1']
      excluded_lxc_keys = ['templated', 'rootfs', 'mp0', 'net0', 'net1']

      it '#server qemu' do
        config_hash = object_to_config_hash(server, 'qemu')
        expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(server.config.attributes).reject { |key, _value| excluded_qemu_keys.include? key }
        assert_equal expected_config_hash, config_hash['config_attributes']
      end

      it '#server lxc' do
        config_hash = object_to_config_hash(server, 'lxc')
        assert config_hash.key?('config_attributes')
        expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(server.config.attributes).reject { |key, _value| excluded_qemu_keys.include? key }
        assert_equal expected_config_hash, config_hash['config_attributes']
      end

      it '#container qemu' do
        config_hash = object_to_config_hash(container, 'qemu')
        assert config_hash.key?('config_attributes')
        expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(container.config.attributes).reject { |key, _value| excluded_lxc_keys.include? key }
        assert_equal expected_config_hash, config_hash['config_attributes']
      end

      it '#container lxc' do
        config_hash = object_to_config_hash(container, 'lxc')
        assert config_hash.key?('config_attributes')
        expected_config_hash = ActiveSupport::HashWithIndifferentAccess.new(container.config.attributes).reject { |key, _value| excluded_lxc_keys.include? key }
        assert_equal expected_config_hash, config_hash['config_attributes']
      end
    end
  end
end
