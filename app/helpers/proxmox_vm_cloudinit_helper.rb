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
module ProxmoxVmCloudinitHelper
  def parse_server_cloudinit(args)
    cloudinit_h = {}
    cloudinit = args['cloudinit']
    unless ['none'].include? cloudinit
      volid = args['volid']
      storage = args['storage']
      cloudinit_volid = volid if volid
      cloudinit_volid ||= "#{storage}:cloudinit" if storage
      controller = args['controller']
      device = args['device']
      id = "#{controller}#{device}" if controller && device
      cloudinit_h.store(:id, id.to_sym) if id
      cloudinit_h.store(:volid, cloudinit_volid) if cloudinit_volid
      cloudinit_h.store(:media, 'cdrom')
    end
    cloudinit_h
  end
end
