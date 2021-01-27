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
require 'foreman_fog_proxmox/hash_collection'

# Convert a foreman form server hash into a fog-proxmox server attributes hash
module ProxmoxVmCdromHelper
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

  def parse_server_cdrom(args)
    cdrom = args['cdrom']
    cdrom_image = args['cdrom_iso']
    volid = cdrom_image.empty? ? cdrom : cdrom_image
    return {} unless volid

    cdrom = "#{volid},media=cdrom"
    { ide2: cdrom }
  end
end
