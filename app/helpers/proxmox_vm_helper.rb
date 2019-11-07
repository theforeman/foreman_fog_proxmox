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

module ProxmoxVmHelper
  KILO = 1024
  MEGA = KILO * KILO
  GIGA = KILO * MEGA

  def object_to_config_hash(vm)
    vm_h = ActiveSupport::HashWithIndifferentAccess.new
    main_a = ['hostname', 'name', 'vmid']
    main = vm.attributes.select { |key, _value| main_a.include? key }
    main_a += ['templated']
    config = vm.config.attributes.reject { |key, _value| main_a.include?(key) || Fog::Proxmox::DiskHelper.disk?(key) || Fog::Proxmox::NicHelper.nic?(key) }
    vm_h = vm_h.merge(main)
    vm_h = vm_h.merge('config_attributes': config)
    vm_h
  end

  def add_cdrom_to_config_server(vm, config)
    cd_disks = vm.config.disks.select { |disk| disk.id == 'ide2' }
    cdrom = {}
    disk_to_cdrom(cd_disks.first, cdrom)
    config = config.merge(cdrom)
    config
  end

  def disk_to_cdrom(disk, cdrom)
    volid = disk.volid
    cdrom_a = ['none', 'cdrom']
    if cdrom_a.include? volid
      cdrom.store('cdrom', volid)
    else
      cdrom.store('cdrom', 'image')
      cdrom.store('cdrom_iso', volid)
      cdrom.store('cdrom_storage', disk.storage)
    end
  end

  def convert_sizes(args)
    convert_memory_size(args['config_attributes'], 'memory')
    convert_memory_size(args['config_attributes'], 'min_memory')
    convert_memory_size(args['config_attributes'], 'shares')
    convert_memory_size(args['config_attributes'], 'swap')
    args['volumes_attributes'].each_value { |value| value['size'] = (value['size'].to_i / GIGA).to_s unless ForemanFogProxmox::Value.empty?(value['size']) }
  end

  def remove_deletes(args)
    args['volumes_attributes']&.delete_if { |_key, value| value.key? '_delete' }
  end

  def convert_memory_size(config_hash, key)
    # default unit memory size is Mb
    memory = (config_hash[key].to_i / MEGA).to_s == '0' ? config_hash[key] : (config_hash[key].to_i / MEGA).to_s
    config_hash.store(key, memory)
  end
end
