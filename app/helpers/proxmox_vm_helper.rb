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

  # The four container-feature form toggles own these Proxmox 'features'
  # sub-flags. Any other sub-flag (e.g. mknod, force_rw_sys) can be set
  # out-of-band and must be preserved when the value is rebuilt on edit.
  def feature_toggle_keys
    ['nesting', 'keyctl', 'fuse', 'mount']
  end

  # Reconcile the LXC 'features' config value on an update (edit path only).
  #
  # parse_typed_features rebuilds 'features' from the four form toggles, so:
  #   * disabling the last remaining feature would otherwise omit the key
  #     entirely and PVE would keep the old value (the disable is lost), and
  #   * sub-flags set out-of-band (mknod, force_rw_sys, ...) would be dropped.
  #
  # This merges the toggle values over the container's current 'features'
  # value, keeping unknown sub-flags. When the reconciled value is empty and
  # the container previously had features, the key is explicitly unset through
  # the Proxmox 'delete' mechanism (the same channel used to remove
  # interfaces) rather than omitted. Fresh creates never reach here, so an
  # empty features is never forced on create.
  def reconcile_container_features(vmobj, config_attributes)
    return unless vmobj.config.respond_to?(:features)

    original = features_string_to_hash(vmobj.config.features)
    return if original.empty? && !config_attributes.key?(:features)

    preserved = original.reject { |key, _value| feature_toggle_keys.include?(key) }
    selected = features_string_to_hash(config_attributes[:features])
    merged = selected.merge(preserved)

    config_attributes.delete(:features)
    if merged.empty?
      add_delete_key(config_attributes, 'features') unless original.empty?
    else
      config_attributes[:features] = features_hash_to_string(merged)
    end
  end

  # Append a key to the comma-separated Proxmox 'delete' list without dropping
  # any keys already queued for deletion (e.g. removed interfaces).
  def add_delete_key(config_attributes, key)
    keys = config_attributes[:delete].to_s.split(',').reject(&:empty?)
    keys << key unless keys.include?(key)
    config_attributes[:delete] = keys.join(',')
  end

  def features_string_to_hash(features)
    return {} if ForemanFogProxmox::Value.empty?(features)

    features.to_s.split(',').each_with_object({}) do |part, hash|
      key, value = part.split('=', 2)
      hash[key] = value
    end
  end

  def features_hash_to_string(hash)
    hash.map { |key, value| "#{key}=#{value}" }.join(',')
  end
end
