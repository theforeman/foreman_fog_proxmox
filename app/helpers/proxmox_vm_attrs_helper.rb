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
require 'fog/proxmox/helpers/cpu_helper'
require 'foreman_fog_proxmox/value'
require 'foreman_fog_proxmox/hash_collection'
include ForemanFogProxmox::ProxmoxComputeAttributes
# Convert a foreman form server hash into a fog-proxmox server attributes hash
module ProxmoxVmAttrsHelper
  def object_to_attributes_hash(vm, from_profile)
    paramScope = from_profile ? "compute_attribute[vm_attrs]" : "host[compute_attributes]"
    vm_h = ActiveSupport::HashWithIndifferentAccess.new
    keys = [ :vmid, :node_id, :type, :pool]
    extra_keys = [:cpu_type]
    main = vm.attributes.select { |key, _value| keys.include? key }
    interfaces = Hash[vm.config.interfaces.each_with_index.map do |interface, idx|
	    [idx.to_s, interface_compute_attributes(interface.attributes)]
                                               end ]
    vm.config.all_attributes.each do |key, value|
      if key == :interfaces
        vm_h.merge!({key => {:name => "#{paramScope}[interfaces_attributes]", :value => interfaces }})
      elsif !keys.include? key
        vm_h.merge!({key => {:name => "#{paramScope}[config_attributes][#{key}]", :value => value}})
      end
    end
    main.each do |key, value|
      vm_h.merge!({key => {:name => "#{paramScope}[#{key}]", :value => value}})
    end
    logger.warn("******************* volumes_attrs() #{volumes_attrs(paramScope, vm.volumes)}")
    vm_h.merge!({:pool => {:name => "#{paramScope}[pool]", :value => vm.pool}})
    vm_h.merge!({:cpu_type => {:name => "#{paramScope}[config_attributes][cpu_type]", :value => vm.config.cpu_type}})
    vm_h.merge!({ :disks => volumes_attrs(paramScope, vm.volumes) })
    vm_h.merge(cpu_flags_attrs(paramScope, vm.config))
  end

  def cpu_flags_attrs(paramScope, config)
    flag_attrs = ActiveSupport::HashWithIndifferentAccess.new 
    Fog::Proxmox::CpuHelper.flags.each do |key, _val|
      flag_attrs.merge!({key => {:name => "#{paramScope}[config_attributes][#{key}]", :value => config.public_send(key)}})
    end
    flag_attrs
  end

  def volumes_attrs(paramScope, volumes)
    vol_attrs = []
    volumes.each_with_index do |vol, id|
      keys = []
      type = ""
      if vol.rootfs?
        keys = ['volid', 'storage', 'size']
	type = 'rootfs'
      elsif vol.hard_disk?
        keys = ['id', 'volid', 'storage_type', 'storage', 'controller', 'device', 'cache', 'size']
	type = 'hard_disk'
      elsif  vol.cdrom?
        keys = ['id', 'storage_type', 'cdrom', 'storage', 'volid']
	type = 'cdrom'
      elsif vol.cloudinit?
        keys = ['id', 'volid', 'storage_type', 'storage', 'controller', 'device']
	type = 'cloudinit'
      elsif vol.mount_point?
        keys = ['id', 'volid', 'storage', 'device', 'mp', 'size']
	type = 'mount_point'
      end
      vol_attrs << {:name => type, :value => vol_keys(paramScope, keys, vol, id)}
    end
    vol_attrs
  end

  def vol_keys(paramScope, keys, vol, id)
    attrs = ActiveSupport::HashWithIndifferentAccess.new
    keys.each do |key|
      attrs[key] = {:name => "#{paramScope}[volumes_attributes][#{id}][#{key}]", :value => vol.public_send(key)}
    end
    attrs
  end

  def network_attrs(paramScope, interfaces)

  end
end
