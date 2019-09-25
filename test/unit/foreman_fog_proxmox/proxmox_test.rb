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
require 'unit/foreman_fog_proxmox/proxmox_test_helpers'

module ForemanFogProxmox
  class ProxmoxTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ForemanFogProxmox::ProxmoxTestHelpers
    include ProxmoxVmHelper

    should validate_presence_of(:url)
    should validate_presence_of(:user)
    should validate_presence_of(:password)
    should validate_presence_of(:node_id)
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

    test '#node' do
      node = mock('node')
      cr = FactoryBot.build_stubbed(:proxmox_cr)
      cr.stubs(:node).returns(node)
      assert_equal node, (as_admin { cr.node })
    end

    describe 'destroy_vm' do
      it 'handles situation when vm is not present' do
        cr = mock_cr_servers(ForemanFogProxmox::Proxmox.new, empty_servers)
        cr.expects(:find_vm_by_uuid).raises(ActiveRecord::RecordNotFound)
        assert cr.destroy_vm('abc')
      end
    end

    describe 'find_vm_by_uuid' do
      it 'returns nil when the uuid does not match' do
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, empty_servers, empty_servers)
        assert cr.find_vm_by_uuid('100').nil?
      end

      it 'raises RecordNotFound when the compute raises error' do
        exception = Fog::Errors::Error.new
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers_raising_exception(exception))
        assert_raises ActiveRecord::RecordNotFound do
          cr.find_vm_by_uuid('100')
        end
      end

      it 'finds vm on other node in cluster' do
        args = { vmid: '100', type: 'qemu' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        servers.stubs(:get).with(args[:vmid]).returns(args)
        cr = mock_cluster_nodes_servers_containers(
          ForemanFogProxmox::Proxmox.new,
          empty_servers, empty_servers, # node1
          servers, empty_servers        # node2
        )
        assert_equal args, cr.find_vm_by_uuid(args[:vmid])
      end
    end

    describe 'host_interfaces_attrs' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'raises Foreman::Exception when physical identifier does not match net[k] with k integer' do
        physical_nic = FactoryBot.build(:nic_base_empty, :identifier => 'eth0')
        host = FactoryBot.build(:host_empty, :interfaces => [physical_nic])
        err = assert_raises Foreman::Exception do
          @cr.host_interfaces_attrs(host)
        end
        assert err.message.end_with?('Invalid identifier interface[0]. Must be net[n] with n integer >= 0')
      end

      it 'sets compute id with identifier, ip and ip6' do
        ip = IPAddr.new(1, Socket::AF_INET).to_s
        ip6 = Array.new(4) { format('%x', rand(16**4)) }.join(':') + '::1'
        physical_nic = FactoryBot.build(:nic_base_empty, :identifier => 'net0', :ip => ip, :ip6 => ip6)
        host = FactoryBot.build(
          :host_empty,
          :interfaces => [physical_nic],
          :compute_attributes => {
            'type' => 'qemu',
            'interfaces_attributes' => {
              '0' => physical_nic
            }
          }
        )
        nic_attributes = @cr.host_interfaces_attrs(host).values.select(&:present?)
        nic_attr = nic_attributes.first
        assert_equal 'net0', nic_attr[:id]
        assert_equal ip, nic_attr[:ip]
        assert_equal ip6, nic_attr[:ip6]
      end
    end

    describe 'host_compute_attrs' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'raises Foreman::Exception when server ostype does not match os family' do
        operatingsystem = FactoryBot.build(:solaris)
        physical_nic = FactoryBot.build(:nic_base_empty, :identifier => 'net0', :primary => true)
        host = FactoryBot.build(
          :host_empty,
          :interfaces => [physical_nic],
          :operatingsystem => operatingsystem,
          :compute_attributes => {
            'type' => 'qemu',
            'config_attributes' => {
              'ostype' => 'l26'
            },
            'interfaces_attributes' => {
              '0' => physical_nic
            }
          }
        )
        err = assert_raises Foreman::Exception do
          @cr.host_compute_attrs(host)
        end
        assert err.message.end_with?('Operating system family Solaris is not consistent with l26')
      end

      it 'sets container hostname with host name' do
        physical_nic = FactoryBot.build(:nic_base_empty, :identifier => 'net0', :primary => true)
        host = FactoryBot.build(
          :host_empty,
          :interfaces => [physical_nic],
          :compute_attributes => {
            'type' => 'lxc',
            'config_attributes' => {
              'hostname' => ''
            },
            'interfaces_attributes' => {
              '0' => {}
            }
          }
        )
        @cr.host_compute_attrs(host)
        assert_equal host.name, host.compute_attributes['config_attributes']['hostname']
      end
    end

    describe 'vm_compute_attributes' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'converts a server to hash' do
        vm, config_attributes, volume_attributes, interface_attributes = mock_server_vm
        vm_attrs = @cr.vm_compute_attributes(vm)
        assert_not vm_attrs.key?(:config)
        assert vm_attrs.key?(:config_attributes)
        assert_equal config_attributes.reject { |key, value| [:vmid, :disks, :interfaces].include?(key) || value.to_s.empty? }, vm_attrs[:config_attributes]
        assert_not vm_attrs[:config_attributes].key?(:disks)
        assert vm_attrs.key?(:volumes_attributes)
        assert_equal volume_attributes, vm_attrs[:volumes_attributes]['0']
        assert_not vm_attrs[:config_attributes].key?(:interfaces)
        assert vm_attrs.key?(:interfaces_attributes)
        assert_equal interface_attributes, vm_attrs[:interfaces_attributes]['0']
      end

      it 'converts a container to hash' do
        vm, config_attributes, volume_attributes, interface_attributes = mock_container_vm
        vm_attrs = @cr.vm_compute_attributes(vm)
        assert_not vm_attrs.key?(:config)
        assert vm_attrs.key?(:config_attributes)
        assert_equal config_attributes.reject { |key, value| [:vmid, :disks, :interfaces].include?(key) || value.to_s.empty? }, vm_attrs[:config_attributes]
        assert_not vm_attrs[:config_attributes].key?(:disks)
        assert vm_attrs.key?(:volumes_attributes)
        assert_equal volume_attributes, vm_attrs[:volumes_attributes]['0']
        assert vm_attrs.key?(:interfaces_attributes)
        assert_equal interface_attributes, vm_attrs[:interfaces_attributes]['0']
      end
    end

    describe 'save_vm' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'saves modified server config with same volumes' do
        uuid = '100'
        config = mock('config')
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        attr = { 'templated' => '0', 'config_attributes' => { 'cores' => '1', 'cpulimit' => '1' } }
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        expected_attr = { :cores => '1', :cpulimit => '1' }
        vm.expects(:update, expected_attr)
        @cr.save_vm(uuid, attr)
      end

      it 'saves server as template' do
        uuid = '100'
        config = mock('config')
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:templated?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        attr = { 'templated' => '1' }
        vm.expects(:create_template)
        @cr.save_vm(uuid, attr)
      end

      it 'saves modified server config with added volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:volid).returns('local-lvm:vm-0815-disk-0')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('virtio0')
        disks.stubs(:get).returns
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'scsi0',
              'storage' => 'local-lvm',
              'size' => '2147483648',
              'cache' => 'none'
            }
          }
        }
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = { id: 'scsi0', storage: 'local:lvm', size: (2_147_483_648 / GIGA).to_s }
        vm.expects(:attach, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified server config with removed volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:volid).returns('local-lvm:vm-0815-disk-0')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('virtio0')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              '_delete' => '1',
              'id' => 'scsi0',
              'volid' => 'local-lvm:vm-0815-disk-0',
              'storage' => 'local-lvm',
              'size' => '2147483648',
              'cache' => 'none'
            }
          }
        }
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = 'scsi0'
        vm.expects(:detach, expected_volume_attr)
        vm.expects(:detach, 'unused0')
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified server config with removed interfaces' do
        uuid = '100'
        config = mock('config')
        interfaces = mock('interfaces')
        interface = mock('interface')
        interface.stubs(:id).returns('net0')
        interfaces.stubs(:get).returns(interface)
        config.stubs(:interfaces).returns(interfaces)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'interfaces_attributes' => {
            '0' => {
              '_delete' => '1',
              'id' => 'net0'
            }
          }
        }
        @cr.stubs(:parse_server_vm).returns(
          'vmid' => '100',
          'type' => 'qemu',
          'cores' => '1',
          'cpulimit' => '1',
          'delete' => 'net0'
        )
        expected_config_attr = { :cores => '1', :cpulimit => '1', :delete => 'net0' }
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified server config with resized volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:volid).returns('local-lvm:vm-0815-disk-0')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'scsi0',
              'volid' => 'local-lvm:vm-0815-disk-0',
              'storage' => 'local-lvm',
              'size' => '2147483648',
              'cache' => 'none'
            }
          }
        }
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = ['scsi0', '+1G']
        vm.expects(:extend, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'raises error unable to shrink volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:volid).returns('local-lvm:vm-0815-disk-0')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'scsi0',
              'volid' => 'local-lvm:vm-0815-disk-0',
              'storage' => 'local-lvm',
              'size' => '2',
              'cache' => 'none'
            }
          }
        }
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        # FIXME: is this neccessary?
        # expected_config_attr = { :cores => '1', :cpulimit => '1' }
        err = assert_raises Foreman::Exception do
          @cr.save_vm(uuid, new_attributes)
        end
        assert err.message.end_with?('Unable to shrink scsi0 size. Proxmox allows only increasing size.')
      end

      it 'saves modified server config with moved volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:volid).returns('local-lvm:vm-0815-disk-0')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('qemu')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'scsi0',
              'volid' => 'local-lvm2:vm-0815-disk-0',
              'storage' => 'local-lvm2',
              'size' => '1073741824',
              'cache' => 'none'
            }
          }
        }
        @cr.stubs(:parse_server_vm).returns('vmid' => '100', 'type' => 'qemu', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = ['scsi0', 'local-lvm2']
        vm.expects(:move, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified container config' do
        uuid = '100'
        config = mock('config')
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(true)
        vm.stubs(:type).returns('lxc')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        attr = { 'templated' => '0', 'config_attributes' => { 'cores' => '1', 'cpulimit' => '1' } }
        @cr.stubs(:parse_container_vm).returns('vmid' => '100', 'type' => 'lxc', 'cores' => '1', 'cpulimit' => '1')
        expected_attr = { :cores => '1', :cpulimit => '1' }
        vm.expects(:update, expected_attr)
        @cr.save_vm(uuid, attr)
      end

      it 'saves modified container config with added volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('rootfs')
        disks.stubs(:get).returns
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('lxc')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes = {
          'templated' => '0',
          'config_attributes' => {
            'cores' => '1',
            'cpulimit' => '1'
          },
          'volumes_attributes' => {
            '0' => {
              'id' => 'mp0',
              'storage' => 'local-lvm',
              'size' => '2147483648',
              'cache' => 'none',
              'mp' => '/opt/path'
            }
          }
        }
        @cr.stubs(:parse_container_vm).returns('vmid' => '100', 'type' => 'lxc', 'cores' => '1', 'cpulimit' => '1')
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr =
          [
            {
              id: 'mp0',
              storage: 'local:lvm',
              size: (2_147_483_648 / GIGA).to_s
            },
            {
              mp: '/opt/path'
            }
          ]
        vm.expects(:attach, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end

      it 'saves modified container config with resized volumes' do
        uuid = '100'
        config = mock('config')
        disks = mock('disks')
        disk = mock('disk')
        disk.stubs(:volid).returns('local-lvm:vm-0815-disk-0')
        disk.stubs(:size).returns(1_073_741_824)
        disk.stubs(:storage).returns('local-lvm')
        disk.stubs(:id).returns('rootfs')
        disks.stubs(:get).returns(disk)
        config.stubs(:disks).returns(disks)
        config.stubs(:attributes).returns(:cores => '')
        vm = mock('vm')
        vm.stubs(:config).returns(config)
        vm.stubs(:container?).returns(false)
        vm.stubs(:type).returns('lxc')
        @cr.stubs(:find_vm_by_uuid).returns(vm)
        new_attributes =
          {
            'templated' => '0',
            'config_attributes' => {
              'cores' => '1',
              'cpulimit' => '1'
            },
            'volumes_attributes' => {
              '0' => {
                'id' => 'rootfs',
                'volid' => 'local-lvm:vm-0815-disk-0',
                'storage' => 'local-lvm',
                'size' => '2147483648',
                'cache' => 'none'
              }
            }
          }
        @cr.stubs(:parse_container_vm).returns(
          'vmid' => '100',
          'type' => 'lxc',
          'cores' => '1',
          'cpulimit' => '1'
        )
        expected_config_attr = { :cores => '1', :cpulimit => '1' }
        expected_volume_attr = ['rootfs', '+1G']
        vm.expects(:extend, expected_volume_attr)
        vm.expects(:update, expected_config_attr)
        @cr.save_vm(uuid, new_attributes)
      end
    end

    describe 'create_vm' do
      it 'raises Foreman::Exception when vmid is invalid' do
        args = { vmid: '100' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(false)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        err = assert_raises Foreman::Exception do
          cr.create_vm(args)
        end
        assert err.message.end_with?('invalid vmid=100')
      end

      it 'creates server' do
        args = { vmid: '100', type: 'qemu' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:convert_sizes).with(args)
        cr.stubs(:parse_server_vm).with(args).returns(args)
        servers.stubs(:create).with(args)
        vm = mock('vm')
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.create_vm(args)
      end

      it 'creates container' do
        args = { vmid: '100', type: 'lxc' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        containers = mock('containers')
        containers.stubs(:create).with(vmid: 100, type: 'lxc')
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, containers)
        cr.stubs(:convert_sizes).with(args)
        cr.stubs(:parse_container_vm).with(args).returns(args)
        vm = mock('vm')
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.create_vm(args)
      end

      it 'clones server' do
        args = { vmid: '100', type: 'qemu', image_id: '999', name: 'name' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        cr = mock_node_servers(ForemanFogProxmox::Proxmox.new, servers)
        cr.stubs(:convert_sizes).with(args)
        cr.stubs(:parse_server_vm).with(args).returns(args)
        servers.stubs(:create).with(args)
        image = mock('image')
        clone = mock('clone')
        image.stubs(:clone).with(100)
        servers.stubs(:get).with(100).returns(clone)
        servers.stubs(:get).with('999').returns(image)
        clone.stubs(:update).with(name: 'name')
        vm = mock('vm')
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.create_vm(args)
      end

      it 'clones container' do
        args = { vmid: '100', type: 'lxc', image_id: '999', name: 'name' }
        servers = mock('servers')
        servers.stubs(:id_valid?).returns(true)
        containers = mock('containers')
        containers.stubs(:create).with(vmid: 100, type: 'lxc')
        image = mock('image')
        clone = mock('clone')
        image.stubs(:clone).with(100)
        servers.stubs(:get).with(100).returns(clone)
        servers.stubs(:get).with('999').returns(image)
        clone.stubs(:update).with(name: 'name')
        cr = mock_node_servers_containers(ForemanFogProxmox::Proxmox.new, servers, containers)
        cr.stubs(:convert_sizes).with(args)
        cr.stubs(:parse_container_vm).with(args).returns(args)
        vm = mock('vm')
        cr.stubs(:find_vm_by_uuid).with((args[:vmid]).to_s).returns(vm)
        cr.create_vm(args)
      end
    end

    describe 'new_vm' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'new server with attr empty' do
        attr = {}
        vm = mock('vm')
        config = mock('config')
        config.stubs(:inspect).returns('config')
        vm.stubs(:config).returns(config)
        @cr.stubs(:new_server_vm).with(attr).returns(vm)
        assert_equal vm, @cr.new_vm(attr)
      end

      it 'new server with attr not empty' do
        attr = { 'type' => 'qemu' }
        vm = mock('vm')
        config = mock('config')
        config.stubs(:inspect).returns('config')
        vm.stubs(:config).returns(config)
        @cr.stubs(:new_server_vm).with(attr).returns(vm)
        assert_equal vm, @cr.new_vm(attr)
      end

      it 'new container with attr not empty' do
        attr = { 'type' => 'lxc' }
        vm = mock('vm')
        config = mock('config')
        config.stubs(:inspect).returns('config')
        vm.stubs(:config).returns(config)
        @cr.stubs(:new_container_vm).with(attr).returns(vm)
        assert_equal vm, @cr.new_vm(attr)
      end
    end
  end
end
