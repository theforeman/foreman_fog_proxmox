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

module ForemanFogProxmox
  module ProxmoxComputeAttributes
    FOREMAN_INTERFACE_ATTRIBUTES = [:id, :mac, :ip, :ip6].freeze
    PROXMOX_MAC_ATTRIBUTES = [:macaddr, :hwaddr].freeze
    PROXMOX_INTERFACE_METADATA = [:identifier, :compute_attributes].freeze

    def host_compute_attrs(host)
      config = host.compute_attributes['config_attributes'] || {}
      ostype = config['ostype']
      type = host.compute_attributes['type']
      case type
      when 'lxc'
        host.compute_attributes['config_attributes'].store('hostname', host.name)
      when 'qemu'
        host.compute_attributes['config_attributes'].store('name', host.name)
        unless compute_os_types(host).include?(ostype)
          raise ::Foreman::Exception,
            format(_('Operating system family %<type>s is not consistent with %<ostype>s'), type: host.operatingsystem.type,
              ostype: ostype)
        end
      end
      super
    end

    def not_config_key?(vm, key)
      [:disks, :interfaces, :vmid, :node_id, :node, :type].include?(key) || !vm.config.respond_to?(key)
    end

    def interface_compute_attributes(interface_attributes)
      attrs = interface_attributes.with_indifferent_access
      provider_attrs = attrs[:compute_attributes].present? ? attrs[:compute_attributes].with_indifferent_access : ActiveSupport::HashWithIndifferentAccess.new

      vm_attrs = FOREMAN_INTERFACE_ATTRIBUTES.index_with do |key|
        attrs[key] || provider_attrs.delete(key)
      end.compact
      vm_attrs[:mac] ||= attrs[:macaddr] || attrs[:hwaddr] || provider_attrs.delete(:macaddr) || provider_attrs.delete(:hwaddr)

      attrs.except(*FOREMAN_INTERFACE_ATTRIBUTES, *PROXMOX_MAC_ATTRIBUTES, *PROXMOX_INTERFACE_METADATA).each do |key, value|
        provider_attrs[key] = value
      end

      provider_attrs[:dhcp] = (vm_attrs[:ip] == 'dhcp') ? '1' : '0'
      provider_attrs[:dhcp6] = (vm_attrs[:ip6] == 'dhcp') ? '1' : '0'
      vm_attrs[:compute_attributes] = provider_attrs
      vm_attrs
    end

    def cdrom_compute_attributes(attrs)
      return unless attrs[:storage_type].to_s == 'cdrom' || attrs[:media].to_s == 'cdrom'

      { cdrom: attrs[:volid].to_s }
    end

    def volume_compute_attributes(volume_attributes)
      attrs = volume_attributes.merge(_delete: '0')
      cdrom_compute_attributes(attrs) || attrs
    end

    def vm_compute_attributes(vm)
      vm_attrs = { vmid: vm.identity, node_id: vm.node_id, type: vm.type }
      vm_attrs[:full_clone] = vm.try(:full_clone) if vm.try(:full_clone).present?
      return vm_attrs unless vm.respond_to?(:config)

      vm_attrs.merge(vm_config_compute_attributes(vm))
    end

    private

    def vm_config_compute_attributes(vm)
      attrs = { config_attributes: vm_raw_config_attributes(vm) }
      attrs[:volumes_attributes] = vm_volumes_compute_attributes(vm) if vm.config.respond_to?(:disks)
      attrs[:interfaces_attributes] = vm_interfaces_compute_attributes(vm) if vm.config.respond_to?(:interfaces)
      attrs
    end

    def vm_volumes_compute_attributes(vm)
      Hash[vm.config.disks.each_with_index.map { |disk, idx| [idx.to_s, volume_compute_attributes(disk.attributes)] }]
    end

    def vm_interfaces_compute_attributes(vm)
      Hash[vm.config.interfaces.each_with_index.map { |iface, idx| [idx.to_s, interface_compute_attributes(iface.attributes)] }]
    end

    def vm_raw_config_attributes(vm)
      vm.config.attributes.reject do |key, value|
        not_config_key?(vm, key) || ForemanFogProxmox::Value.empty?(value.to_s) ||
          Fog::Proxmox::DiskHelper.disk?(key.to_s) || Fog::Proxmox::NicHelper.nic?(key.to_s)
      end
    end
  end
end
