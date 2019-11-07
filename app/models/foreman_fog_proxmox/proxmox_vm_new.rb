# frozen_string_literal: true

# Copyright 2019 Tristan Robert

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

require 'fog/proxmox'
require 'fog/proxmox/helpers/nic_helper'
require 'fog/proxmox/helpers/disk_helper'

module ForemanFogProxmox
  module ProxmoxVmNew
    include ProxmoxVmHelper

    def volume_server_defaults(controller = 'scsi', device = 0)
      id = "#{controller}#{device}"
      { id: id, storage: storages.first.identity.to_s, size: (8 * GIGA), options: { cache: 'none' } }
    end

    def volume_container_defaults(id = 'rootfs')
      { id: id, storage: storages.first.identity.to_s, size: (8 * GIGA), options: {} }
    end

    def new_volume(attr = {})
      type = attr['type']
      type ||= 'qemu'
      case type
      when 'lxc'
        return new_volume_server(attr)
      when 'qemu'
        return new_volume_container(attr)
      end
    end

    def new_volume_server(attr = {})
      opts = volume_server_defaults.merge(attr.to_h).deep_symbolize_keys
      opts[:size] = opts[:size].to_s
      Fog::Proxmox::Compute::Disk.new(opts)
    end

    def new_volume_container(attr = {})
      opts = volume_container_defaults.merge(attr.to_h).deep_symbolize_keys
      opts[:size] = opts[:size].to_s
      Fog::Proxmox::Compute::Disk.new(opts)
    end

    def interface_defaults(id = 'net0')
      { id: id, model: 'virtio', name: 'eth0', bridge: bridges.first.identity.to_s }
    end

    def interface_server_defaults(id = 'net0')
      { id: id, model: 'virtio', bridge: bridges.first.identity.to_s }
    end

    def interface_container_defaults(id = 'net0')
      { id: id, name: 'eth0', bridge: bridges.first.identity.to_s }
    end

    def new_interface(attr = {})
      type = attr['type']
      type ||= 'qemu'
      case type
      when 'lxc'
        return new_container_interface(attr)
      when 'qemu'
        return new_server_interface(attr)
      end
    end

    def new_server_interface(attr = {})
      logger.debug('new_server_interface')
      opts = interface_server_defaults.merge(attr.to_h).deep_symbolize_keys
      Fog::Proxmox::Compute::Interface.new(opts)
    end

    def new_container_interface(attr = {})
      logger.debug('new_container_interface')
      opts = interface_container_defaults.merge(attr.to_h).deep_symbolize_keys
      Fog::Proxmox::Compute::Interface.new(opts)
    end

    def vm_server_instance_defaults
      ActiveSupport::HashWithIndifferentAccess.new(
        name: "foreman_#{Time.now.to_i}",
        vmid: next_vmid,
        type: 'qemu',
        node_id: node_id,
        cores: 1,
        sockets: 1,
        kvm: 1,
        vga: 'std',
        memory: 512 * MEGA,
        ostype: 'l26',
        keyboard: 'en-us',
        cpu: 'kvm64',
        scsihw: 'virtio-scsi-pci',
        ide2: 'none,media=cdrom',
        templated: 0
      ).merge(Fog::Proxmox::DiskHelper.flatten(volume_server_defaults)).merge(Fog::Proxmox::DiskHelper.flatten(volume_container_defaults)).merge(Fog::Proxmox::NicHelper.flatten(interface_defaults))
    end

    def vm_container_instance_defaults
      ActiveSupport::HashWithIndifferentAccess.new(
        name: "foreman_#{Time.now.to_i}",
        vmid: next_vmid,
        type: 'lxc',
        node_id: node_id,
        memory: 512 * MEGA,
        templated: 0
      ).merge(Fog::Proxmox::DiskHelper.flatten(volume_container_defaults)).merge(Fog::Proxmox::DiskHelper.flatten(volume_server_defaults)).merge(Fog::Proxmox::NicHelper.flatten(interface_defaults))
    end

    def vm_instance_defaults
      super.merge(vmid: next_vmid, node_id: node_id)
    end

    def new_vm(new_attr = {})
      new_attr = ActiveSupport::HashWithIndifferentAccess.new(new_attr)
      type = new_attr['type']
      type ||= 'qemu'
      case type
      when 'lxc'
        vm = new_container_vm(new_attr)
      when 'qemu'
        vm = new_server_vm(new_attr)
      end
      logger.debug(format(_('new_vm() vm.config=%<config>s'), config: vm.config.inspect))
      vm
    end

    def new_container_vm(new_attr = {})
      options = new_attr
      options = options.merge(node_id: node_id).merge(type: 'lxc').merge(vmid: next_vmid)
      options = vm_container_instance_defaults.merge(options) if new_attr.empty?
      vm = node.containers.new(parse_container_vm(options).deep_symbolize_keys)
      logger.debug(format(_('new_container_vm() vm.config=%<config>s'), config: vm.config.inspect))
      vm
    end

    def new_server_vm(new_attr = {})
      options = new_attr
      options = options.merge(node_id: node_id).merge(type: 'qemu').merge(vmid: next_vmid)
      options = vm_server_instance_defaults.merge(options) if new_attr.empty?
      vm = node.servers.new(parse_server_vm(options).deep_symbolize_keys)
      logger.debug(format(_('new_server_vm() vm.config=%<config>s'), config: vm.config.inspect))
      vm
    end
  end
end
