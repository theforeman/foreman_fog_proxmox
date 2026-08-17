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
require 'foreman_fog_proxmox/hash_collection'
require 'foreman_fog_proxmox/value'

module ProxmoxVMHelper
  include ProxmoxVMInterfacesHelper
  include ProxmoxVMVolumesHelper
  include ProxmoxVMImageTemplateHelper
  include ProxmoxVMConfigHelper
  include ProxmoxVMOsTemplateHelper
  include ProxmoxVMEfidiskHelper

  def vm_collection(type)
    collection = :servers
    collection = :containers if type == 'lxc'
    collection
  end

  def parse_vm_update_attributes(attributes, type)
    ForemanFogProxmox::HashCollection.new_hash_reject_keys(
      attributes, ['volumes_attributes']
    ).merge(type: type)
  end

  def update_boot_order(instance, exclude_cdrom: false, include_network: false)
    return {} unless instance

    disks = Array(instance.disks).map { |disk| disk.split(":")[0] }
    disks.delete("ide2") if exclude_cdrom
    network_interfaces = include_network ? Array(instance.interfaces).map(&:id) : []
    boot_devices = network_interfaces + disks

    return {} if boot_devices.empty?

    { boot: "order=" + boot_devices.join(";") }
  end

  # Convert a foreman form server/container vm hash into a fog-proxmox server/container attributes hash
  def parse_typed_vm(args, type)
    args = process_firmware_attributes(args, type)
    args = ActiveSupport::HashWithIndifferentAccess.new(args)
    return {} unless args
    return {} if args.empty?
    return {} unless args['type'] == type

    logger.debug("parse_typed_vm(#{type}): args=#{args}")
    parsed_vm = parsed_typed_config(args, type)
    parsed_vm = parsed_typed_efidisk(args, type, parsed_vm)
    parsed_vm = parsed_typed_interfaces(args, type, parsed_vm)
    parsed_vm = parsed_typed_volumes(args, type, parsed_vm)
    logger.debug("parse_typed_vm(#{type}): parsed_vm=#{parsed_vm}")
    parsed_vm
  end
end
