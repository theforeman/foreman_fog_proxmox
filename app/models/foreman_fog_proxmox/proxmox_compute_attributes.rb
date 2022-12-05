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
    def host_compute_attrs(host)
      ostype = host.compute_attributes['config_attributes']['ostype']
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
      vm_attrs = ForemanFogProxmox::HashCollection.new_hash_reject_keys(interface_attributes, [:identifier, :mac])
      vm_attrs[:dhcp] = interface_attributes[:ip] == 'dhcp' ? '1' : '0'
      vm_attrs[:dhcp6] = interface_attributes[:ip6] == 'dhcp' ? '1' : '0'
      vm_attrs
    end

    def vm_compute_attributes(vm)
      vm_attrs = {}
      vm_attrs = vm_attrs.merge(vmid: vm.identity, node_id: vm.node_id, type: vm.type)
      if vm.respond_to?(:config)
        if vm.config.respond_to?(:disks)
          vm_attrs[:volumes_attributes] = Hash[vm.config.disks.each_with_index.map do |disk, idx|
                                                 [idx.to_s, disk.attributes]
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
