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
module ProxmoxVMVolumesHelper
  include ProxmoxVMCdromHelper
  include ProxmoxVMCloudinitHelper

  def add_disk_options(disk, args)
    options = ForemanFogProxmox::HashCollection.new_hash_reject_keys(args,
      ['id', 'volid', 'controller', 'device', 'storage', 'size', '_delete', 'storage_type'])
    ForemanFogProxmox::HashCollection.remove_empty_values(options)
    disk[:options] = options
  end

  def parsed_typed_volumes(args, type, parsed_vm)
    logger.debug("parsed_typed_volumes(#{type}): args=#{args}")
    volumes_attributes = args['volumes_attributes']
    unless ForemanFogProxmox::Value.empty?(args['config_attributes'])
      volumes_attributes ||= args['config_attributes']['volumes_attributes']
    end
    unless ForemanFogProxmox::Value.empty?(args['vm_attrs'])
      volumes_attributes ||= args['vm_attrs']['volumes_attributes']
    end
    volumes = parse_typed_volumes(volumes_attributes, type)
    volumes.each { |volume| parsed_vm = parsed_vm.merge(volume) }
    parsed_vm
  end

  def parse_hard_disk_volume(args)
    logger.debug(format(_('parse_hard_disk_volume(): args=%<args>s'), args: args))
    disk = {}
    disk[:id] = args['id'] if args.key?('id')
    disk[:volid] = args['volid'] if args.key?('volid') && !args['volid'].empty?
    disk[:storage] = args['storage'].to_s if args.key?('storage') && !args['storage'].empty?
    disk[:size] = args['size'].to_i if args.key?('size') && !args['size'].empty?
    args['backup'] = '1' if args.key?('backup') && args['backup'].nil?
    add_disk_options(disk, args) unless args.key?('options')
    disk[:options] = args['options'] if args.key?('options')
    disk.key?(:storage) ? disk : {}
  end

  def volume_type?(args, type)
    if args.key?('storage_type')
      args['storage_type'] == type
    else
      Fog::Proxmox::DiskHelper.cloud_init?(args['volid']) if type == 'cloud_init'
      Fog::Proxmox::DiskHelper.cdrom?(args['volid']) if type == 'cdrom'
      Fog::Proxmox::DiskHelper.disk?(args['id']) if ['hard_disk', 'rootfs', 'mp'].include?(type)
    end
  end

  def parse_typed_volume(args, type)
    logger.debug("parse_typed_volume(#{type}): args=#{args}")
    disk = parse_hard_disk_volume(args) if volume_type?(args,
      'hard_disk') || volume_type?(args, 'mp') || volume_type?(args, 'rootfs')
    disk = parse_server_cloudinit(args) if volume_type?(args, 'cloud_init')
    disk = parse_server_cdrom(args) if volume_type?(args, 'cdrom')
    logger.debug("parse_typed_volume(#{type}): disk=#{disk}")
    Fog::Proxmox::DiskHelper.flatten(disk) unless disk.empty?
  end

  def add_typed_volume(volumes, value, type)
    volume = parse_typed_volume(value, type)
    volumes.push(volume) unless ForemanFogProxmox::Value.empty?(volume)
  end

  def parse_typed_volumes(args, type)
    logger.debug("parse_typed_volumes(#{type}): args=#{args}")
    volumes = []
    args&.each_value { |value| add_typed_volume(volumes, value, type) }
    volumes
  end

  def remove_volume_keys(args)
    if args.key?('volumes_attributes')
      args['volumes_attributes'].each_value do |volume_attributes|
        ForemanFogProxmox::HashCollection.remove_keys(volume_attributes, ['_delete'])
      end
    end
  end
end
