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

module ForemanFogProxmox
  module ProxmoxContainerMockFactory
    def mock_container_interface_attributes
      compute_attributes = {
        model: nil,
        name: 'eth0',
        hwaddr: '36:25:8C:53:0C:50',
        ip: nil,
        ip6: nil,
        gw: nil,
        gw6: nil,
        bridge: 'vmbr0',
        firewall: nil,
        link_down: nil,
        rate: nil,
        queues: nil,
        tag: nil,
      }
      {
        id: 'net0',
        mac: '36:25:8C:53:0C:50',
        ip: nil,
        ip6: nil,
        compute_attributes: compute_attributes,
      }
    end

    def mock_container_vm
      interface = mock('interface')
      interface.stubs(:attributes).returns(mock_container_interface_attributes)
      interfaces = [interface]
      volume_attributes = {
        id: 'rootfs',
        volid: 'local-lvm:vm-100-disk-1',
        size: 8,
        storage: 'local-lvm',
        cache: 'none',
        replicate: nil,
        media: nil,
        format: nil,
        model: 'rootfs',
        shared: nil,
        snapshot: nil,
        backup: nil,
        aio: nil,
      }
      volume = mock('volume')
      volume.stubs(:attributes).returns(volume_attributes)
      volumes = [volume]
      config = mock('config')
      config_attributes = {
        vmid: 100,
        digest: '0',
        ostype: 'alpine',
        storage: 'local-lvm',
        template: 0,
        arch: 'amd64',
        memory: 512,
        swap: nil,
        hostname: 'test',
        nameserver: nil,
        searchdomain: nil,
        password: 'proxmox01',
        onboot: 0,
        startup: nil,
        cores: 1,
        cpuunits: nil,
        cpulimit: nil,
        description: nil,
        console: nil,
        cmode: nil,
        tty: nil,
        force: nil,
        lock: nil,
        pool: nil,
        bwlimit: nil,
        unprivileged: nil,
        interfaces: interfaces,
        disks: volumes,
      }
      config.stubs(:attributes).returns(config_attributes)
      config.stubs(:attributes).returns(config_attributes)
      config.stubs(:disks).returns(volumes)
      config.stubs(:interfaces).returns(interfaces)
      config.stubs(:respond_to?).returns(true)
      vm = mock('vm')
      vm.stubs(:respond_to?).returns(true)
      vm.stubs(:config).returns(config)
      vm.stubs(:type).returns('lxc')
      vm.stubs(:identity).returns(100)
      vm.stubs(:node_id).returns('proxmox')
      vm.stubs(:identity).returns(100)
      service = mock('service')
      vm_attributes = {
        vmid: 100,
        id: 'lxc/100',
        node_id: 'proxmox',
        service: service,
        config: config,
        name: 'test',
        type: 'lxc',
        maxdisk: 0,
        disk: 0,
        diskwrite: 0,
        diskread: 0,
        uptime: 0,
        netout: 0,
        netin: 0,
        cpu: 1,
        cpus: 1,
        template: 0,
        status: 'stopped',
        maxcpu: 0,
        mem: 0,
        maxmem: 512,
        qmpstatus: 'stopped',
        ha: {},
        pid: 0,
        blockstat: 0,
        balloon: 0,
        ballooninfo: 0,
        snapshots: [],
      }
      vm.stubs(:attributes).returns(vm_attributes)
      vm.stubs(:container?).returns(true)
      [vm, config_attributes, volume_attributes, mock_container_interface_attributes]
    end
  end
end
