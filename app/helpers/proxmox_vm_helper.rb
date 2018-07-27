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

  def object_to_hash(vm)
    vm_h = ActiveSupport::HashWithIndifferentAccess.new
    main_a = %w[name type node vmid]
    main_a += [:name, :type, :node, :vmid]
    main = vm.config.attributes.select { |key,_value| main_a.include? key }
    disks_regexp = /^(scsi|sata|mp|rootfs|virtio|ide)(\d+)/
    nics_regexp = /^(net)(\d+)/
    main_a += %w[templated]
    config = vm.config.attributes.reject { |key,_value| main_a.include?(key) || disks_regexp.match(key) || nics_regexp.match(key)  }
    vm_h = vm_h.merge(main)
    vm_h = vm_h.merge({'config_attributes': config})
    interfaces = []
    vm.config.interfaces.each { |interface| interfaces.push(Fog::Proxmox::NicHelper.flatten(interface.attributes)) }
    vm_h = vm_h.merge({'interfaces_attributes': interfaces})
    volumes = []
    vm.config.disks.each { |disk| volumes.push(Fog::Proxmox::DiskHelper.flatten(disk.attributes)) unless disk.id == 'ide2' }
    vm_h = vm_h.merge({'volumes_attributes': volumes})
    vm_h
  end

end