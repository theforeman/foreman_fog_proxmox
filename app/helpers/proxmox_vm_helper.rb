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

  def object_to_config_hash(vm,type)
    return vm.config.attributes if vm.type == type
    vm_h = ActiveSupport::HashWithIndifferentAccess.new
    main_a = %w[name type node vmid]
    main_a += [:name, :type, :node, :vmid]
    type = vm.config.attributes['type']
    type = vm.type unless type
    main = vm.config.attributes.select { |key,_value| main_a.include? key }
    disks_regexp = /^(scsi|sata|mp|rootfs|virtio|ide)(\d+){0,1}$/
    nics_regexp = /^(net)(\d+)/
    main_a += %w[templated]
    config = vm.config.attributes.reject { |key,_value| main_a.include?(key) || disks_regexp.match(key) || nics_regexp.match(key)  }
    vm_h = vm_h.merge(main)
    # config = add_cdrom_to_config_server(vm,config) unless (vm.container? && type == 'lxc')
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

end