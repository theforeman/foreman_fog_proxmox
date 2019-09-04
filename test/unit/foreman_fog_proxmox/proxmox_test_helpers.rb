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
  module ProxmoxTestHelpers
    def mock_node_servers(cr, servers)
      node = mock('node')
      node.stubs(:servers).returns(servers)
      cr.stubs(:nodes).returns([node])
      cr.stubs(:node).returns(node)
      cr
    end

    def mock_node_containers(cr, containers)
      node = mock('node')
      node.stubs(:containers).returns(containers)
      cr.stubs(:node).returns(node)
      cr.stubs(:nodes).returns([node])
      cr
    end

    def mock_node_servers_containers(cr, servers, containers)
      node = mock('node')
      node.stubs(:containers).returns(containers)
      node.stubs(:servers).returns(servers)
      cr.stubs(:node).returns(node)
      cr.stubs(:nodes).returns([node])
      cr
    end

    def mock_cluster_nodes_servers_containers(cr, n1s, n1c, n2s, n2c)
      node1 = mock('node')
      node1.stubs(:node).returns('node1')
      node1.stubs(:servers).returns(n1s)
      node1.stubs(:containers).returns(n1c)
      node2 = mock('node')
      node2.stubs(:node).returns('node2')
      node2.stubs(:servers).returns(n2s)
      node2.stubs(:containers).returns(n2c)
      cr.stubs(:node).returns(node1)
      cr.stubs(:nodes).returns([node1, node2])
      cr
    end

    def mock_server_vm
      interface_attributes = {
        id: 'net0',
        macaddr: '36:25:8C:53:0C:50',
        model: 'virtio',
        name: nil,
        ip: nil,
        ip6: nil,
        bridge: 'vmbr0',
        firewall: nil,
        link_down: nil,
        rate: nil,
        queues: nil,
        tag: nil
      }
      interface = mock('interface')
      interface.stubs(:attributes).returns(interface_attributes)
      interfaces = [interface]
      volume_attributes = {
        id: 'scsi0',
        volid: 'local-lvm:vm-100-disk-1',
        size: 8,
        storage: 'local-lvm',
        cache: 'none',
        replicate: nil,
        media: nil,
        format: nil,
        model: 'scsi',
        shared: nil,
        snapshot: nil,
        backup: nil,
        aio: nil
      }
      volume = mock('volume')
      volume.stubs(:attributes).returns(volume_attributes)
      volumes = [volume]
      config = mock('config')
      config_attributes = {
        vmid: 100,
        digest: '0',
        description: '',
        ostype: 'l26',
        smbios1: '0',
        numa: 0,
        kvm: 0,
        vcpus: 1,
        cores: 1,
        bootdisk: 'scsi0',
        onboot: 0,
        boot: 'scsi0',
        agent: 0,
        scsihw: 'scsi',
        sockets: 1,
        memory: 512,
        min_memory: 0,
        shares: 0,
        balloon: 0,
        name: 'test',
        cpu: 1,
        cpulimit: nil,
        cpuunits: nil,
        keyboard: 'fr',
        vga: 'std',
        interfaces: interfaces,
        disks: volumes
      }
      config.stubs(:attributes).returns(config_attributes)
      config.stubs(:disks).returns(volumes)
      config.stubs(:interfaces).returns(interfaces)
      config.stubs(:respond_to?).returns(true)
      vm = mock('vm')
      vm.stubs(:respond_to?).returns(true)
      vm.stubs(:config).returns(config)
      vm.stubs(:type).returns('qemu')
      vm.stubs(:identity).returns(100)
      vm.stubs(:node_id).returns('pve')
      service = mock('service')
      vm_attributes = {
        vmid: 100,
        id: 'qemu/100',
        node_id: 'pve',
        config: config,
        service: service,
        name: 'test',
        type: 'qemu',
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
        snapshots: []
      }
      vm.stubs(:attributes).returns(vm_attributes)
      vm.stubs(:container?).returns(false)
      [vm, config_attributes, volume_attributes, interface_attributes]
    end

    def mock_container_vm
      interface_attributes = {
        id: 'net0',
        mac: '36:25:8C:53:0C:50',
        model: nil,
        name: 'eth0',
        ip: nil,
        ip6: nil,
        bridge: 'vmbr0',
        firewall: nil,
        link_down: nil,
        rate: nil,
        queues: nil,
        tag: nil
      }
      interface = mock('interface')
      interface.stubs(:attributes).returns(interface_attributes)
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
        aio: nil
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
        disks: volumes
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
      vm.stubs(:node_id).returns('pve')
      vm.stubs(:identity).returns(100)
      service = mock('service')
      vm_attributes = {
        vmid: 100,
        id: 'lxc/100',
        node_id: 'pve',
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
        snapshots: []
      }
      vm.stubs(:attributes).returns(vm_attributes)
      vm.stubs(:container?).returns(true)
      [vm, config_attributes, volume_attributes, interface_attributes]
    end
  end
end
