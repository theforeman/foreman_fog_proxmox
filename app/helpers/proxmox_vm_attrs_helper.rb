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

# Convert a foreman form server hash into a fog-proxmox server attributes hash
module ProxmoxVMAttrsHelper
  def object_to_attributes_hash(vms, from_profile, start_checked)
    param_scope = from_profile ? "compute_attribute[vm_attrs]" : "host[compute_attributes]"
    vm_h = ActiveSupport::HashWithIndifferentAccess.new
    keys = [:vmid, :node_id, :type, :pool]
    main = vms.attributes.select { |key, _value| keys.include? key }
    vms.config.all_attributes.each do |key, value|
      camel_key = key.to_s.include?('_') ? snake_to_camel(key.to_s).to_sym : key
      vm_h[camel_key] = { :name => "#{param_scope}[config_attributes][#{key}]", :value => value } unless keys.include? key
    end
    main.each do |key, value|
      camel_key = key.to_s.include?('_') ? snake_to_camel(key.to_s).to_sym : key
      vm_h[camel_key] = { :name => "#{param_scope}[#{key}]", :value => value } if keys.include? key
    end

    vm_h.merge!(additional_attrs(vms, param_scope, start_checked))
    vm_h[:interfaces] = network_attrs(param_scope, vms.interfaces)
    vm_h[:disks] = volumes_attrs(param_scope, vms.volumes)
    vm_h.merge(cpu_flags_attrs(param_scope, vms.config))
  end

  def cpu_flags_attrs(param_scope, config)
    flag_attrs = ActiveSupport::HashWithIndifferentAccess.new
    Fog::Proxmox::CpuHelper.flags.each do |key, _val|
      flag_attrs.merge!({ key => { :name => "#{param_scope}[config_attributes][#{key}]", :value => config.public_send(key) } })
    end
    flag_attrs
  end

  def volumes_attrs(param_scope, volumes)
    vol_attrs = []
    volumes.each_with_index do |vol, id|
      keys = []
      type = ""
      if vol.rootfs?
        keys = ['id', 'volid', 'storage', 'size', 'storage_type']
        type = 'rootfs'
      elsif vol.hard_disk?
        keys = ['id', 'volid', 'storage_type', 'storage', 'controller', 'device', 'cache', 'backup', 'size']
        type = 'hard_disk'
      elsif  vol.cdrom?
        keys = ['id', 'storage_type', 'cdrom', 'storage', 'volid']
        type = 'cdrom'
      elsif vol.cloud_init?
        keys = ['id', 'volid', 'storage_type', 'storage', 'controller', 'device']
        type = 'cloud_init'
      elsif vol.mount_point?
        keys = ['id', 'volid', 'storage_type', 'storage', 'device', 'mp', 'size']
        type = 'mount_point'
      end
      vol_attrs << { :name => type, :value => vol_keys(param_scope, keys, vol, id) }
    end
    vol_attrs
  end

  def vol_keys(param_scope, keys, vol, id)
    attrs = ActiveSupport::HashWithIndifferentAccess.new
    keys.each do |key|
      camel_key = key.to_s.include?('_') ? snake_to_camel(key.to_s).to_sym : key
      attrs[camel_key] = { :name => "#{param_scope}[volumes_attributes][#{id}][#{key}]", :value => vol.public_send(key) }
    end
    attrs
  end

  def network_attrs(param_scope, interfaces)
    networks_attrs = []
    interfaces.each_with_index do |interface, id|
      attrs = ActiveSupport::HashWithIndifferentAccess.new
      interface.all_attributes.each do |key, value|
        camel_key = key.to_s.include?('_') ? snake_to_camel(key.to_s).to_sym : key
        attrs[camel_key] = { :name => "#{param_scope}[interfaces_attributes][#{id}][#{key}]", :value => value }
      end
      networks_attrs << { :name => 'interface', :value => attrs }
    end
    networks_attrs
  end

  def additional_attrs(vms, param_scope, start_checked)
    attributes = {
      pool: vms.pool,
      image_id: vms.image_id,
      cpu_type: vms.config.cpu_type,
      nameserver: vms.config.nameserver,
      searchdomain: vms.config.searchdomain,
      hostname: vms.config.hostname,
      ostemplate_storage: vms.ostemplate_storage,
      ostemplate_file: vms.ostemplate_file,
      start_after_create: vms.start_after_create,
      templated: vms.templated,
    }
    vms_keys = [:cpu_type, :nameserver, :searchdomain, :hostname]
    extra_attrs = ActiveSupport::HashWithIndifferentAccess.new
    attributes.each do |key, value|
      camel_key = key.to_s.include?('_') ? snake_to_camel(key.to_s).to_sym : key
      nested_key = vms_keys.include?(key) ? "config_attributes[#{key}]" : key
      value = start_checked if key == :start_after_create
      extra_attrs[camel_key] = { name: "#{param_scope}[#{nested_key}]", value: value }
    end
    extra_attrs
  end

  def snake_to_camel(str)
    str.split('_').inject([]) { |buffer, e| buffer.push(buffer.empty? ? e : e.capitalize) }.join
  end
end
