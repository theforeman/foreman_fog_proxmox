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
require 'foreman_fog_proxmox/hash_collection'

module ForemanFogProxmox
  module ProxmoxVMNew
    include ProxmoxVMHelper

    def cdrom_defaults
      { storage_type: 'cdrom', id: 'ide2', volid: 'none', media: 'cdrom' }
    end

    def cloudinit_defaults
      { storage_type: 'cloud_init', id: 'ide0', storage: storages.first.identity.to_s, media: 'cdrom' }
    end

    def hard_disk_typed_defaults(vm_type)
      options = {}
      volume_attributes_h = { storage: storages.first.identity.to_s, size: '8' }
      case vm_type
      when 'qemu'
        controller = 'virtio'
        device = 0
        id = "#{controller}#{device}"
        options = { cache: 'none', backup: '1' }
        volume_attributes_h = volume_attributes_h.merge(controller: controller, device: device)
      when 'lxc'
        id = 'rootfs'
        volume_attributes_h = volume_attributes_h.merge(storage_type: 'rootfs')
      end
      volume_attributes_h[:id] = id
      volume_attributes_h[:options] = options
      volume_attributes_h
    end

    def new_typed_volume(attr, vm_type, volume_type)
      volume_defaults = hard_disk_typed_defaults(vm_type) if ['hard_disk', 'rootfs', 'mp'].include?(volume_type)
      volume_defaults = cdrom_defaults if volume_type == 'cdrom'
      volume_defaults = cloudinit_defaults if volume_type == 'cloud_init'
      opts = volume_defaults.merge(attr.to_h).deep_symbolize_keys
      opts = ForemanFogProxmox::HashCollection.new_hash_transform_values(opts, :to_s)
      Fog::Proxmox::Compute::Disk.new(opts)
    end

    def new_volume(attr = {})
      type = attr['type']
      type ||= 'qemu'
      new_typed_volume(attr, type, 'hard_disk')
    end

    def interface_defaults(id = 'net0')
      { id: id, compute_attributes: { model: 'virtio', name: 'eth0', bridge: bridges.first.identity.to_s } }
    end

    def interface_typed_defaults(type)
      interface_attributes_h = { id: 'net0', compute_attributes: {} }
      if type == 'qemu'
        interface_attributes_h[:compute_attributes] =
          { model: 'virtio', bridge: bridges.first.identity.to_s }
      end
      if type == 'lxc'
        interface_attributes_h[:compute_attributes] =
          { name: 'eth0', bridge: bridges.first.identity.to_s, dhcp: 1, dhcp6: 1 }
      end
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

    def add_default_typed_interface(type, new_attr)
      interfaces_attributes = []
      interfaces_attributes.push(interface_typed_defaults(type))
      new_attr = new_attr.merge(interfaces_attributes: interfaces_attributes.map.with_index.to_h.invert)
      logger.debug("add_default_typed_interface(#{type}) to new_attr=#{new_attr}")
      new_attr
    end

    def add_default_typed_volume(new_attr)
      volumes_attributes = []
      volumes_attributes.push(hard_disk_typed_defaults('qemu'))
      volumes_attributes.push(hard_disk_typed_defaults('lxc'))
      new_attr = new_attr.merge(volumes_attributes: volumes_attributes.map.with_index.to_h.invert)
      logger.debug("add_default_typed_volume(#{type}) to new_attr=#{new_attr}")
      new_attr
    end

    def vm_instance_defaults
      super.merge(vmid: next_vmid, node_id: default_node_id, type: 'qemu')
    end

    def vm_typed_instance_defaults(type)
      defaults = vm_instance_defaults
      defaults = defaults.merge(config_attributes: config_attributes(type))
      defaults = add_default_typed_volume(defaults)
      add_default_typed_interface(type, defaults)
    end

    def config_attributes(type = 'qemu')
      case type
      when 'qemu'
        config_attributes = {
          cores: '1',
          sockets: '1',
          kvm: '1',
          vga: 'std',
          memory: '1024',
          ostype: 'l26',
          cpu: 'cputype=kvm64',
          scsihw: 'virtio-scsi-pci',
          templated: '0',
        }
        config_attributes = config_attributes
      when 'lxc'
        config_attributes = {
          memory: '1024',
          templated: '0',
        }
      end
      config_attributes
    end

    def new_vm(new_attr = {})
      new_attr = ActiveSupport::HashWithIndifferentAccess.new(new_attr)
      type = new_attr['type']
      type ||= 'qemu'
      new_typed_vm(new_attr, type)
    end

    def convert_config_attributes(new_attr)
      config_attributes = new_attr[:config_attributes]
      if config_attributes.key?(:disks)
        config_attributes[:volumes_attributes] = Hash[config_attributes[:disks].each_with_index.map do |disk, idx|
                                                        [idx.to_s, disk.attributes]
                                                      end ]
      end
      if config_attributes.key?(:interfaces)
        config_attributes[:interfaces_attributes] = Hash[config_attributes[:interfaces].each_with_index.map do |interface, idx|
                                                           [idx.to_s, interface_compute_attributes(interface.attributes)]
                                                         end ]
      end
      config_attributes.delete_if { |key, _value| ['disks', 'interfaces'].include?(key) }
    end

    def new_typed_vm(new_attr, type)
      convert_config_attributes(new_attr) if new_attr.key?(:config_attributes)
      node_id = new_attr['node_id']
      node = node_id ? client.nodes.get(node_id) : default_node
      new_attr_type = new_attr['type']
      new_attr_type ||= new_attr['config_attributes']['type'] if new_attr.key?('config_attributes')
      new_attr_type ||= type
      logger.debug("new_typed_vm(#{type}): new_attr_type=#{new_attr_type}")
      logger.debug("new_typed_vm(#{type}): new_attr=#{new_attr}'")
      options = (!new_attr.key?('vmid') || ForemanFogProxmox::Value.empty?(new_attr['vmid'])) ? vm_typed_instance_defaults(type).merge(new_attr).merge(type: type) : new_attr
      logger.debug("new_typed_vm(#{type}): options=#{options}")
      vm_h = parse_typed_vm(options, type).deep_symbolize_keys
      logger.debug("new_typed_vm(#{type}): vm_h=#{vm_h}")
      vm_h = vm_h.merge(vm_typed_instance_defaults(type)) if vm_h.empty?
      logger.debug(format(_('new_typed_vm(%<type>s) with vm_typed_instance_defaults: vm_h=%<vm_h>s'), type: type, vm_h: vm_h))
      node.send(vm_collection(type)).new(vm_h)
    end
  end
end
