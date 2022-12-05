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

require 'fog/proxmox/helpers/disk_helper'
require 'fog/proxmox/helpers/nic_helper'
require 'foreman_fog_proxmox/value'
require 'foreman_fog_proxmox/hash_collection'

# Convert a foreman form server hash into a fog-proxmox server attributes hash
module ProxmoxVmInterfacesHelper
  def parsed_typed_interfaces(args, type, parsed_vm)
    interfaces_to_add, interfaces_to_delete = parse_typed_interfaces(args, type)
    interfaces_to_add.each { |interface| parsed_vm = parsed_vm.merge(interface) }
    parsed_vm = parsed_vm.merge(delete: interfaces_to_delete.join(',')) unless interfaces_to_delete.empty?
    parsed_vm
  end

  def parse_typed_interfaces(args, type)
    interfaces_to_add = []
    interfaces_to_delete = []
    interfaces_attributes = args['interfaces_attributes']
    unless ForemanFogProxmox::Value.empty?(args['config_attributes'])
      interfaces_attributes ||= args['config_attributes']['interfaces_attributes']
    end
    interfaces_attributes&.each_value do |value|
      add_or_delete_typed_interface(value, interfaces_to_delete, interfaces_to_add, type)
    end
    [interfaces_to_add, interfaces_to_delete]
  end

  def interface_compute_attributes_typed_keys(type)
    keys = ['rate', 'bridge', 'tag']
    case type
    when 'qemu'
      keys += ['model', 'firewall', 'link_down', 'queues']
    when 'lxc'
      keys += ['name', 'ip', 'ip6', 'gw', 'gw6', 'dhcp', 'dhcp6', 'cidr', 'cidr6', 'firewall']
    end
    keys
  end

  def interface_common_typed_keys(type)
    [{ origin: 'id', dest: 'id' }, { origin: 'mac', dest: type == 'qemu' ? 'macaddr' : 'hwaddr' }]
  end

  def compute_dhcps(interface_attributes_h)
    interface_attributes_h[:dhcp] = interface_attributes_h[:ip] == 'dhcp' ? '1' : '0'
    interface_attributes_h[:ip] = '' if interface_attributes_h[:dhcp] == '1'
    interface_attributes_h[:dhcp6] = interface_attributes_h[:ip6] == 'dhcp' ? '1' : '0'
    interface_attributes_h[:ip6] = '' if interface_attributes_h[:dhcp6] == '1'
  end

  def add_or_delete_typed_interface(interface_attributes, interfaces_to_delete, interfaces_to_add, type)
    logger.debug("add_or_delete_typed_interface(#{type}): interface_attributes=#{interface_attributes}")
    ForemanFogProxmox::HashCollection.remove_empty_values(interface_attributes)
    if interface_attributes['compute_attributes']
      ForemanFogProxmox::HashCollection.remove_empty_values(interface_attributes['compute_attributes'])
    end
    nic = {}
    id = interface_attributes['id']
    delete = interface_attributes['_delete'].to_i == 1
    if delete
      logger.debug("add_or_delete_typed_interface(#{type}): delete id=#{id}")
      interfaces_to_delete.push(id.to_s)
    else
      interface_common_typed_keys(type).each do |key|
        ForemanFogProxmox::HashCollection.add_and_format_element(nic, key[:dest].to_sym, interface_attributes,
          key[:origin])
      end
      interface_attributes_h = interface_attributes['compute_attributes']
      if ForemanFogProxmox::Value.empty?(interface_attributes['compute_attributes'])
        interface_attributes_h ||= interface_attributes
      end
      interface_compute_attributes_typed_keys(type).each do |key|
        ForemanFogProxmox::HashCollection.add_and_format_element(nic, key.to_sym, interface_attributes_h, key)
      end
      compute_dhcps(interface_attributes_h)
      logger.debug("add_or_delete_typed_interface(#{type}): add nic=#{nic}")
      interfaces_to_add.push(Fog::Proxmox::NicHelper.flatten(nic))
    end
  end
end
