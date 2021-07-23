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

require 'fog/proxmox/helpers/ip_helper'
require 'net/validations'

module ForemanFogProxmox
  module ProxmoxInterfaces
    def editable_network_interfaces?
      true
    end

    def set_nic_identifier(nic, index)
      nic.compute_attributes[:id] = format('net%<index>s', index: index) if nic.compute_attributes[:id].empty?
      raise ::Foreman::Exception, _(format('Invalid proxmox NIC id on interface[%<index>s]. Must be net[n] with n integer >= 0', index: index)) unless Fog::Proxmox::NicHelper.nic?(nic.compute_attributes[:id])

      nic.identifier = nic.compute_attributes['id'] if nic.identifier.empty?
    end

    def vm_type(host)
      type = host.compute_attributes['type']
      type ||= host.compute_attributes[:config_attributes].key?(:arch) ? 'lxc' : 'qemu'
      type
    end

    def container?(host)
      vm_type(host) == 'lxc'
    end

    def container_nic_name_valid?(nic)
      /^(eth)(\d+)$/.match?(nic.compute_attributes['name'])
    end

    def set_container_interface_name(_host, nic, index)
      nic.compute_attributes['name'] = format('eth%<index>s', index: index) if nic.compute_attributes['name'].empty?
      raise ::Foreman::Exception, _(format('Invalid name interface[%<index>s]. Must be eth[n] with n integer >= 0', index: index)) unless container_nic_name_valid?(nic)
    end

    def cidr_prefix(nic_compute_attributes, v6 = false)
      attr_name = "cidr#{v6_s(v6)}"
      nic_compute_attributes[attr_name] if nic_compute_attributes.key?(attr_name)
    end

    def cidr_prefix_method(v6)
      "cidr#{v6_s(v6)}_prefix?".to_sym
    end

    def check_cidr(nic_compute_attributes, v6, ip)
      valid = Fog::Proxmox::IpHelper.send(cidr_prefix_method(v6), cidr_prefix(nic_compute_attributes, v6))
      ipv = "IPv#{v6 ? '6' : '4'}"
      max = v6 ? 128 : 32
      checked = valid || ForemanFogProxmox::Value.empty?(ip)
      message = format('Invalid Interface Proxmox CIDR %<ip>s. If %<ip>s is not empty, Proxmox CIDR prefix must be an integer between 0 and %<max>i.', ip: ipv, max: max)
      raise ::Foreman::Exception, _(message) unless checked
    end

    def v6_s(v6)
      v6 ? '6' : ''
    end

    def ip_s(v6)
      "ip#{v6_s(v6)}"
    end

    def to_cidr_method(v6)
      "to_cidr#{v6_s(v6)}".to_sym
    end

    def set_ip(host, nic, nic_compute_attributes, v6 = false)
      ip = nic.send(ip_s(v6).to_sym)
      if container?(host)
        if dhcp?(nic_compute_attributes, v6)
          ip = 'dhcp'
        elsif !ForemanFogProxmox::Value.empty?(cidr_prefix(nic_compute_attributes, v6))
          check_cidr(nic_compute_attributes, v6, ip)
          ip = Fog::Proxmox::IpHelper.send(to_cidr_method(v6), nic.send(ip_s(v6).to_sym), cidr_prefix(nic_compute_attributes, v6)) if ip
        end
      end
      nic_compute_attributes[ip_s(v6).to_sym] = ip
    end

    def to_boolean(value)
      [1, true, '1', 'true'].include?(value)
    end

    def dhcp?(nic_compute_attributes, v6 = false)
      attr_name = "dhcp#{v6_s(v6)}"
      nic_compute_attributes.key?(attr_name) ? to_boolean(nic_compute_attributes[attr_name]) : false
    end

    def set_mac(nic_compute_attributes, mac, type)
      mac_attr_name = { 'qemu' => :macaddr, 'lxc' => :hwaddr }
      mac_key = mac_attr_name[type] || 'mac'
      nic_compute_attributes[mac_key] = Net::Validations.normalize_mac(mac)
    end

    def host_interfaces_attrs(host)
      host.interfaces.select(&:physical?).each.with_index.reduce({}) do |hash, (nic, index)|
        set_nic_identifier(nic, index)
        set_container_interface_name(host, nic, index) if container?(host)
        ForemanFogProxmox::HashCollection.remove_empty_values(nic.compute_attributes)
        mac = nic.mac
        mac ||= nic.attributes['mac']
        set_mac(nic.compute_attributes, mac, vm_type(host)) if mac.present?
        interface_compute_attributes = host.compute_attributes['interfaces_attributes'] ? host.compute_attributes['interfaces_attributes'].select { |_k, v| v['id'] == nic.compute_attributes[:id] } : {}
        nic.compute_attributes.store(:_delete, interface_compute_attributes[interface_compute_attributes.keys[0]]['_delete']) unless interface_compute_attributes.empty?
        set_ip(host, nic, nic.compute_attributes)
        set_ip(host, nic, nic.compute_attributes, true)
        ForemanFogProxmox::HashCollection.remove_keys(nic.compute_attributes, ['dhcp', 'dhcp6', 'cidr', 'cidr6'])
        hash.merge(index.to_s => nic.compute_attributes)
      end
    end
  end
end
