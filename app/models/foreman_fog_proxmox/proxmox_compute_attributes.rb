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
        ensure_container_login!(host, config['sshkeys'])
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

    # The root password and the SSH public keys are both optional on the form, but a
    # new container needs at least one of them, otherwise it is provisioned with no way
    # to log in. Enforce this only when creating a new host (both are create-only params
    # that are not stored on the VM, so they are legitimately absent when editing).
    def ensure_container_login!(host, sshkeys)
      return unless host.new_record?
      return unless ForemanFogProxmox::Value.empty?(host.compute_attributes['password']) && ForemanFogProxmox::Value.empty?(sshkeys)

      raise ::Foreman::Exception, _('A new container requires a root password or SSH public keys to be able to log in')
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
      vm_attrs = {}
      vm_attrs = vm_attrs.merge(vmid: vm.identity, node_id: vm.node_id, type: vm.type)
      if vm.respond_to?(:config)
        if vm.config.respond_to?(:disks)
          vm_attrs[:volumes_attributes] = Hash[vm.config.disks.each_with_index.map do |disk, idx|
                                                 [idx.to_s, volume_compute_attributes(disk.attributes)]
                                               end ]
        end
        if vm.config.respond_to?(:interfaces)
          vm_attrs[:interfaces_attributes] = Hash[vm.config.interfaces.each_with_index.map do |interface, idx|
                                                    [idx.to_s, interface_compute_attributes(interface.attributes)]
                                                  end ]
        end
        vm_attrs[:config_attributes] = vm.config.attributes.reject do |key, value|
          not_config_key?(vm, key) || ForemanFogProxmox::Value.empty?(value.to_s) || Fog::Proxmox::DiskHelper.disk?(key.to_s) || Fog::Proxmox::NicHelper.nic?(key.to_s)
        end
      end
      vm_attrs
    end
  end
end
