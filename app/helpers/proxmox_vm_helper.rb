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

module ProxmoxVmHelper

  KILO = 1024
  MEGA = KILO * KILO
  GIGA = KILO * MEGA

  def object_to_config_hash(vm,type)
    vm_h = ActiveSupport::HashWithIndifferentAccess.new
    main_a = %w[hostname name type node vmid]
    type = vm.config.attributes['type']
    type = vm.type unless type
    main = vm.config.attributes.select { |key,_value| main_a.include? key }
    disks_regexp = /^(scsi|sata|mp|rootfs|virtio|ide)(\d+){0,1}$/
    nics_regexp = /^(net)(\d+)/
    main_a += %w[templated]
    config = vm.config.attributes.reject { |key,_value| main_a.include?(key) || disks_regexp.match(key) || nics_regexp.match(key)  }
    vm_h = vm_h.merge(main)
    vm_h = vm_h.merge({'config_attributes': config})
    vm_h
  end

  def add_cdrom_to_config_server(vm,config)
    cd_disks = vm.config.disks.select { |disk| disk.id == 'ide2' }
    cdrom = {}
    disk_to_cdrom(cd_disks.first,cdrom)
    config = config.merge(cdrom)
    config
  end

  def disk_to_cdrom(disk,cdrom)
    volid = disk.volid  
    cdrom_a = %w[none cdrom]  
    if cdrom_a.include? volid
      cdrom.store('cdrom',volid)
    else
      cdrom.store('cdrom','image')
      cdrom.store('cdrom_iso',volid)
      cdrom.store('cdrom_storage',disk.storage)
    end
  end

  def convert_sizes(args)
    convert_memory_size(args['config_attributes'],'memory')
    convert_memory_size(args['config_attributes'],'min_memory')
    convert_memory_size(args['config_attributes'],'shares')
    convert_memory_size(args['config_attributes'],'swap')
    args['volumes_attributes'].each_value { |value| value['size'] = (value['size'].to_i / GIGA).to_s unless value['size'].empty? }
  end

  def convert_memory_size(config_hash, key)
    config_hash.store(key, (config_hash[key].to_i / MEGA).to_s) unless config_hash[key].empty?
  end

  def parse_type_and_vmid(uuid)
    uuid_regexp = /^(lxc|qemu)\_(\d+)$/
    raise ::Foreman::Exception.new _("Invalid uuid=[%{uuid}]." % { uuid: uuid }) unless uuid.match(uuid_regexp)
    id_a = uuid.scan(uuid_regexp).first
    type = id_a[0]
    vmid = id_a[1]
    return type, vmid
  end

end