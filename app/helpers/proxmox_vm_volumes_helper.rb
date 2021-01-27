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
module ProxmoxVmVolumesHelper
  KILO = 1024
  MEGA = KILO * KILO
  GIGA = KILO * MEGA

  def add_disk_options(disk, args)
    options = ForemanFogProxmox::HashCollection.new_hash_reject_keys(args, ['id', 'volid', 'controller', 'device', 'storage', 'size', '_delete'])
    disk[:options] = options
  end

  def parsed_typed_volumes(args, type, parsed_vm)
    volumes_attributes = args['volumes_attributes']
    volumes_attributes ||= args['config_attributes']['volumes_attributes'] unless ForemanFogProxmox::Value.empty?(args['config_attributes'])
    volumes_attributes ||= args['vm_attrs']['volumes_attributes'] unless ForemanFogProxmox::Value.empty?(args['vm_attrs'])
    logger.debug("parsed_typed_volumes(#{type}): volumes_attributes=#{volumes_attributes}")
    volumes = parse_typed_volumes(volumes_attributes, type)
    volumes.each { |volume| parsed_vm = parsed_vm.merge(volume) }
    parsed_vm
  end

  def parse_typed_volume(args, type)
    disk = {}
    id = compute_typed_id_disk(args, type)
    logger.debug("parse_typed_volume(#{type}): id=#{id}")

    ForemanFogProxmox::HashCollection.remove_empty_values(args)
    disk[:id] = id
    disk[:volid] = args['volid'] if args.key?('volid')
    disk[:storage] = args['storage'].to_s if args.key?('storage')
    disk[:size] = args['size'].to_i if args.key?('size')
    add_disk_options(disk, args)
    logger.debug("parse_typed_volume(#{type}): disk=#{disk}")
    Fog::Proxmox::DiskHelper.flatten(disk)
  end

  def compute_typed_id_disk(args, type)
    id = args['id']
    case type
    when 'qemu'
      id = "#{args['controller']}#{args['device']}" if args.key?('controller') && args.key?('device') && ForemanFogProxmox::Value.empty?(id)
    when 'lxc'
      id = "mp#{args['device']}" if args.key?('device') && ForemanFogProxmox::Value.empty?(id)
    end
    id
  end

  def add_typed_volume(volumes, value, type)
    volume = parse_typed_volume(value, type)
    logger.debug("add_typed_volume(#{type}): volume=#{volume}")
    volumes.push(volume) unless ForemanFogProxmox::Value.empty?(volume)
  end

  def parse_typed_volumes(args, type)
    volumes = []
    args&.each_value { |value| add_typed_volume(volumes, value, type) }
    logger.debug("parse_typed_volumes(#{type}): volumes=#{volumes}")
    volumes
  end

  def convert_volumes_size(args)
    args['volumes_attributes'].each_value { |value| value['size'] = (value['size'].to_i / GIGA).to_s unless ForemanFogProxmox::Value.empty?(value['size']) }
  end

  def convert_sizes(args)
    convert_memory_size(args['config_attributes'], 'memory')
    convert_memory_size(args['config_attributes'], 'balloon')
    convert_memory_size(args['config_attributes'], 'shares')
    convert_memory_size(args['config_attributes'], 'swap')
    args['volumes_attributes'].each_value { |value| value['size'] = (value['size'].to_i / GIGA).to_s unless ForemanFogProxmox::Value.empty?(value['size']) }
  end

  def remove_deletes(args)
    args['volumes_attributes']&.delete_if { |_key, value| value.key? '_delete' }
  end
end
