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
    include ProxmoxVmHelper

    describe 'parse' do
      setup { Fog.mock! }
      teardown { Fog.unmock! }

      let(:type) do
        'lxc'
      end

      let(:host_form) do
        { 'vmid' => '100',
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
            'hostname' => 'toto-tata.pve',
            'nameserver' => '',
            'searchdomain' => '',

          },
          'volumes_attributes' => {
            '0' => { 'id' => 'rootfs', 'storage' => 'local-lvm', 'size' => '1', 'cache' => '' },
            '1' => { 'id' => 'mp0', 'storage' => 'local-lvm', 'size' => '1', 'mp' => '/opt/path' },
          },
          'interfaces_attributes' => {
            '0' => {
              'id' => 'net0',
              'compute_attributes' => {
                'name' => 'eth0',
                'bridge' => 'vmbr0',
                'ip' => 'dhcp',
                'ip6' => 'dhcp',
                'rate' => '',
                'gw' => '192.168.56.100',
                'gw6' => '2001:0:1234::c1c0:abcd:876',
              },
            },
            '1' => {
              'id' => 'net1',
              'compute_attributes' => {
                'name' => 'eth1',
                'bridge' => 'vmbr0',
                'ip' => 'dhcp',
                'ip6' => 'dhcp',
                'gw' => '192.168.56.100',
                'gw6' => '2001:0:1234::c1c0:abcd:876',
              },
            },
          } }
      end

      let(:container) do
        { 'vmid' => '100',
          :vmid => '100',
          'hostname' => 'toto-tata.pve',
          'type' => 'lxc',
          :type => 'lxc',
          'node_id' => 'proxmox',
          :node_id => 'proxmox',
          :memory => '1024',
          'templated' => '0',
          :onboot => '0',
          :swap => '512',
          'cores' => '1',
          :arch => 'amd64',
          :ostype => 'debian',
          'ostemplate' => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
          'ostemplate_storage' => 'local',
          'ostemplate_file' => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
          'password' => 'proxmox01',
          :rootfs => 'local-lvm:1',
          :mp0 => 'local-lvm:1,mp=/opt/path',
          'net0' => 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp,gw=192.168.56.100,gw6=2001:0:1234::c1c0:abcd:876',
          'net1' => 'model=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp,gw=192.168.56.100,gw6=2001:0:1234::c1c0:abcd:876' }
      end

      let(:host_delete) do
        { 'vmid' => '100',
          'name' => 'test',
          'type' => 'lxc',
          'node_id' => 'proxmox',
          'volumes_attributes' => { '0' => { '_delete' => '1', 'device' => '0', 'storage' => 'local-lvm', 'size' => '1', 'mp' => '/opt/path' } },
          'interfaces_attributes' => { '0' => { '_delete' => '1', 'id' => 'net0', 'name' => 'eth0' } } }
      end

      test '#memory' do
        memory = parse_typed_memory(host_form['config_attributes'].select { |key, _value| config_typed_keys(type)[:memory].include? key }, type)
        assert memory.key?('memory')
        assert_equal '1024', memory['memory']
        assert memory.key?('swap')
        assert_equal '512', memory['swap']
      end

      test '#cpu' do
        cpu = parse_typed_cpu(host_form['config_attributes'].select { |key, _value| config_typed_keys(type)[:cpu].include? key }, type)
        assert cpu.key?(:arch)
        assert_equal 'amd64', cpu[:arch]
      end

      test '#ostemplate' do
        ostemplate = parse_container_ostemplate(host_form)
        expected_ostemplate = {
          :ostemplate => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
        }
        assert_equal expected_ostemplate, ostemplate
      end

      test '#vm container' do
        vm = parse_typed_vm(host_form, type)
        expected_vm = ActiveSupport::HashWithIndifferentAccess.new(
          :vmid => '100',
          :password => 'proxmox01',
          :ostemplate => 'local:vztmpl/alpine-3.7-default_20171211_amd64.tar.xz',
          :onboot => '0',
          :memory => '1024',
          :swap => '512',
          :cores => '1',
          :arch => 'amd64',
          :ostype => 'debian',
          :hostname => 'toto-tata.pve',
          :net0 => 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp,gw=192.168.56.100,gw6=2001:0:1234::c1c0:abcd:876',
          :net1 => 'name=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp,gw=192.168.56.100,gw6=2001:0:1234::c1c0:abcd:876',
          :rootfs => 'local-lvm:1',
          :mp0 => 'local-lvm:1,mp=/opt/path'
        )
        assert_equal expected_vm, vm
      end

      test '#volume with rootfs 1Gb' do
        volumes = parse_typed_volumes(host_form['volumes_attributes'], type)
        assert_not volumes.empty?
        assert_equal 2, volumes.size
        assert rootfs = volumes.first
        assert rootfs.key?(:rootfs)
        assert_equal 'local-lvm:1', rootfs[:rootfs]
        assert mp0 = volumes[1]
        assert mp0.key?(:mp0)
        assert_equal 'local-lvm:1,mp=/opt/path', mp0[:mp0]
      end

      test '#interface with name eth0 and bridge' do
        deletes = []
        nics = []
        add_or_delete_typed_interface(host_form['interfaces_attributes']['0'], deletes, nics, type)
        assert 1, nics.length
        assert nics[0].key?(:net0)
        assert_equal 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp,gw=192.168.56.100,gw6=2001:0:1234::c1c0:abcd:876',
          nics[0][:net0]
      end

      test '#interface with name eth1 and bridge' do
        deletes = []
        nics = []
        add_or_delete_typed_interface(host_form['interfaces_attributes']['1'], deletes, nics, type)
        assert 1, nics.length
        assert nics[0].key?(:net1)
        assert_equal 'name=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp,gw=192.168.56.100,gw6=2001:0:1234::c1c0:abcd:876',
          nics[0][:net1]
      end

      test '#interface delete net0' do
        deletes = []
        nics = []
        add_or_delete_typed_interface(host_delete['interfaces_attributes']['0'], deletes, nics, type)
        assert_empty nics
        assert_equal 1, deletes.length
        assert_equal 'net0', deletes[0]
      end

      test '#interfaces' do
        interfaces_to_add, interfaces_to_delete = parse_typed_interfaces(host_form, type)
        assert_empty interfaces_to_delete
        assert_equal 2, interfaces_to_add.length
        assert_includes interfaces_to_add,
          { net0: 'name=eth0,bridge=vmbr0,ip=dhcp,ip6=dhcp,gw=192.168.56.100,gw6=2001:0:1234::c1c0:abcd:876' }
        assert_includes interfaces_to_add,
          { net1: 'name=eth1,bridge=vmbr0,ip=dhcp,ip6=dhcp,gw=192.168.56.100,gw6=2001:0:1234::c1c0:abcd:876' }
      end
    end
  end
end
