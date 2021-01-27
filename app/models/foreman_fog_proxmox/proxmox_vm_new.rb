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

    def cdrom_defaults
      { cdrom: 'none' }
    end

    def volume_typed_defaults(type)
      options = {}
      volume_attributes_h = { storage: storages.first.identity.to_s, size: (8 * GIGA) }
      case type
      when 'qemu'
        controller = 'virtio'
        device = 0
        id = "#{controller}#{device}"
        options = { cache: 'none' }
        volume_attributes_h = volume_attributes_h.merge(controller: controller, device: device)
      when 'lxc'
        id = 'rootfs'
      end
      volume_attributes_h[:id] = id
      volume_attributes_h[:options] = options
      volume_attributes_h
    end

    def new_typed_volume(attr, type)
      opts = volume_typed_defaults(type).merge(attr.to_h).deep_symbolize_keys
      opts[:size] = opts[:size].to_s
      Fog::Proxmox::Compute::Disk.new(opts)
    end

    def new_volume(attr = {})
      type = attr['type']
      type ||= 'qemu'
      new_typed_volume(attr, type)
    end

    def interface_defaults(id = 'net0')
      { id: id, compute_attributes: { model: 'virtio', name: 'eth0', bridge: bridges.first.identity.to_s } }
    end

    def interface_typed_defaults(type)
      interface_attributes_h = { id: 'net0', compute_attributes: {} }
      interface_attributes_h[:compute_attributes] = { model: 'virtio', bridge: bridges.first.identity.to_s } if type == 'qemu'
      interface_attributes_h[:compute_attributes] = { name: 'eth0', bridge: bridges.first.identity.to_s, dhcp: 1, dhcp6: 1 } if type == 'lxc'
      interface_attributes_h
    end

    def new_typed_interface(attr, type)
      opts = interface_typed_defaults(type).merge(attr.to_h).deep_symbolize_keys
      Fog::Proxmox::Compute::Interface.new(opts)
    end

    def new_interface(attr = {})
      type = attr['type']
      type ||= 'qemu'
      new_typed_interface(attr, type)
    end

    def default_node
      nodes.first
    end

    def default_node_id
      default_node.node
    end

    def next_vmid
      default_node.servers.next_id
    end

    def vm_instance_defaults
      super.merge(vmid: next_vmid, node_id: default_node_id, type: type)
    end

    def vm_typed_instance_defaults(type)
      defaults = vm_instance_defaults
      volumes_attributes = []
      volumes_attributes.push(volume_typed_defaults('qemu'))
      volumes_attributes.push(volume_typed_defaults('lxc'))
      interfaces_attributes = []
      interfaces_attributes.push(interface_typed_defaults(type))
      defaults = defaults.merge(config_attributes: config_attributes(type))
      defaults = defaults.merge(volumes_attributes: volumes_attributes.map.with_index.to_h.invert)
      defaults = defaults.merge(interfaces_attributes: interfaces_attributes.map.with_index.to_h.invert)
      defaults
    end

    def config_attributes(type = 'qemu')
      case type
      when 'qemu'
        config_attributes = {
          cores: 1,
          sockets: 1,
          kvm: 0,
          vga: 'std',
          memory: 512 * MEGA,
          ostype: 'l26',
          keyboard: 'en-us',
          cpu_type: 'kvm64',
          scsihw: 'virtio-scsi-pci',
          templated: 0
        }
        config_attributes = config_attributes.merge(cdrom_defaults)
      when 'lxc'
        config_attributes = {
          memory: 512 * MEGA,
          templated: 0
        }
      end
      config_attributes
    end

    def new_vm(new_attr = {})
      new_attr = ActiveSupport::HashWithIndifferentAccess.new(new_attr)
      type = new_attr['type']
      type ||= 'qemu'
      vm = new_typed_vm(new_attr, type)
      vm
    end

    def convert_config_attributes(new_attr)
      config_attributes = new_attr[:config_attributes]
      config_attributes[:volumes_attributes] = Hash[config_attributes[:disks].each_with_index.map { |disk, idx| [idx.to_s, disk.attributes] }] if config_attributes.key?(:disks)
      if config_attributes.key?(:interfaces)
        config_attributes[:interfaces_attributes] = Hash[config_attributes[:interfaces].each_with_index.map { |interface, idx| [idx.to_s, interface_compute_attributes(interface.attributes)] }]
      end
      config_attributes.delete_if { |key, _value| ['disks', 'interfaces'].include?(key) }
    end

    def new_typed_vm(new_attr, type)
      convert_config_attributes(new_attr) if new_attr.key?(:config_attributes)
      node_id = new_attr['node_id']
      node = node_id ? client.nodes.get(node_id) : default_node
      new_attr_type = new_attr['type']
      new_attr_type ||= new_attr[:config_attributes]['type'] if new_attr.respond_to?(:config_attributes)
      options = new_attr_type == type ? new_attr : vm_typed_instance_defaults(type)
      options = options.merge(type: type).merge(vmid: next_vmid) if ForemanFogProxmox::Value.empty?(new_attr['vmid'])
      vm = node.send(vm_collection(type)).new(parse_typed_vm(options, type).deep_symbolize_keys)
      vm
    end
  end
end
