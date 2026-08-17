# frozen_string_literal: true

# Copyright 2026 ATIX AG

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

require 'fog/proxmox/helpers/efidisk_helper'
require 'foreman_fog_proxmox/value'
require 'foreman_fog_proxmox/hash_collection'

# Convert a foreman form server hash into a fog-proxmox server attributes hash
module ProxmoxVMEfidiskHelper
  def process_firmware_attributes(args, type)
    return args unless type == 'qemu'
    return args unless args

    normalized_args = ActiveSupport::HashWithIndifferentAccess.new(args)
    config = normalized_args[:config_attributes] || normalized_args
    return args unless config.key?(:bios) || config.key?(:is_secure_boot)

    args = normalized_args

    bios = config[:bios]
    secure_boot_value = config[:is_secure_boot]
    secure_boot = bios == 'uefi_secure_boot' ||
                  (bios == 'ovmf' && Foreman::Cast.to_bool(secure_boot_value))
    config[:is_secure_boot] = secure_boot ? '1' : '0'

    unless secure_boot
      normalize_pre_enrolled_keys(args)
      return args
    end

    config[:bios] = 'ovmf'
    process_secure_boot_efidisk(args, config)
  end

  def normalize_pre_enrolled_keys(args)
    efidisk = args[:efidisk_attributes]
    return args if ForemanFogProxmox::Value.empty?(efidisk)

    efidisk[:pre_enrolled_keys] = '0'
    args
  end

  def process_secure_boot_efidisk(args, config)
    efidisk = args[:efidisk_attributes]
    unless ForemanFogProxmox::Value.empty?(efidisk)
      args[:efidisk_attributes] = secure_boot_efidisk_attributes(
        efidisk.merge('efitype' => '4m', 'pre_enrolled_keys' => '1')
      )
      return args
    end

    volumes = args[:volumes_attributes] || config[:volumes_attributes]
    storage = volumes&.each_value&.filter_map { |volume| volume[:storage] }&.find(&:present?)
    return args if ForemanFogProxmox::Value.empty?(storage)

    args[:efidisk_attributes] = secure_boot_efidisk_attributes(storage: storage)
    args
  end

  def efidisk_defaults(storage)
    {
      'id' => '0',
      'volid' => "#{storage}:0",
      'efitype' => '4m',
      'pre_enrolled_keys' => '1',
    }
  end

  def secure_boot_efidisk_attributes(attr = {})
    attr = attr.to_h.stringify_keys
    efidisk_defaults(attr['storage']).merge(attr)
  end

  def parsed_typed_efidisk(args, type, parsed_vm)
    attrs = args['efidisk_attributes']

    # we need the vmid to create the volid if not present
    vmid = args['vmid'] if args.key?('vmid')
    # fallback to a dummy vmid for new vms
    vmid ||= 'no_vmid_yet'

    logger.debug("parsed_typed_efidisk(#{type}): attrs=#{attrs} with #{vmid}")
    unless ForemanFogProxmox::Value.empty?(args['efidisk_attributes'])
      efidisk = parse_typed_efidisk(attrs, vmid, type)
      logger.debug("parsed_typed_efidisk(#{type}): efidisk=#{efidisk}")
      parsed_vm = parsed_vm.merge(efidisk)
    end
    parsed_vm
  end

  def parse_typed_efidisk(args, _vmid, _type)
    logger.debug(format(_('parse_efidisk(): args=%<args>s'), args: args))
    efidisk = {}
    efidisk[:id] = args['id'] if args.key?('id')
    efidisk[:volid] = args['volid']
    efidisk[:size] = args['size'].to_i if args.key?('size') && !args['size'].empty?
    efidisk[:format] = args['format']
    efidisk[:efitype] = args['efitype'] if args.key?('efitype') && !args['efitype'].empty?
    efidisk[:pre_enrolled_keys] = args['pre_enrolled_keys'] if args.key?('pre_enrolled_keys')
    Fog::Proxmox::EfidiskHelper.flatten(efidisk)
  end
end
