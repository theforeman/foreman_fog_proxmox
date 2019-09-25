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

module ProxmoxServerHelper
  KILO = 1024
  MEGA = KILO * KILO
  GIGA = KILO * MEGA

  def parse_server_vm(args)
    logger.debug("parse_server_vm args=#{args}")
    args = ActiveSupport::HashWithIndifferentAccess.new(args)
    return {} unless args
    return {} if args.empty?
    return {} unless args['type'] == 'qemu'

    config = args['config_attributes']
    main_a = ['name', 'type', 'node_id', 'vmid', 'interfaces', 'mount_points', 'disks']
    config ||= args.reject { |key, _value| main_a.include? key }
    cdrom_a = ['cdrom', 'cdrom_storage', 'cdrom_iso']
    cdrom = parse_server_cdrom(config.select { |key, _value| cdrom_a.include? key })
    vols = args['volumes_attributes']
    volumes = parse_server_volumes(vols)
    cpu_a = ['cpu_type', 'spectre', 'pcid']
    cpu = parse_server_cpu(config.select { |key, _value| cpu_a.include? key })
    memory_a = ['memory', 'min_memory', 'balloon', 'shares']
    memory = parse_server_memory(config.select { |key, _value| memory_a.include? key })
    interfaces_attributes = args['interfaces_attributes']
    interfaces_to_add, interfaces_to_delete = parse_server_interfaces(interfaces_attributes)
    general_a = ['node_id', 'type', 'config_attributes', 'volumes_attributes', 'interfaces_attributes', 'firmware_type', 'provision_method', 'container_volumes', 'server_volumes']
    logger.debug("general_a: #{general_a}")
    parsed_vm = args.reject { |key, value| general_a.include?(key) || ForemanFogProxmox::Value.empty?(value) }
    config_a = []
    config_a += cpu_a
    config_a += cdrom_a
    config_a += memory_a
    config_a += general_a
    parsed_config = config.reject { |key, value| config_a.include?(key) || ForemanFogProxmox::Value.empty?(value) }
    logger.debug("parse_server_config(): #{parsed_config}")
    parsed_vm = parsed_vm.merge(parsed_config).merge(cpu).merge(memory).merge(cdrom)
    interfaces_to_add.each { |interface| parsed_vm = parsed_vm.merge(interface) }
    parsed_vm = parsed_vm.merge(delete: interfaces_to_delete.join(',')) unless interfaces_to_delete.empty?
    volumes.each { |volume| parsed_vm = parsed_vm.merge(volume) }
    logger.debug("parse_server_vm(): #{parsed_vm}")
    parsed_vm
  end

  def parse_server_memory(args)
    memory = {}
    memory.store(:memory, args['memory'].to_i) if args['memory']
    ballooned = args['balloon'].to_i == 1
    if ballooned
      memory.store(:shares, args['shares'].to_i) if args['shares']
      memory.store(:min_memory, args['min_memory'].to_i) if args['min_memory']
    end
    memory.store(:balloon, args['balloon'].to_i) if args['balloon']
    logger.debug("parse_server_memory(): #{memory}")
    memory
  end

  def parse_server_cpu(args)
    return {} unless args['cpu_type']

    cpu = "cputype=#{args['cpu_type']}"
    spectre = args['spectre'].to_i == 1
    pcid = args['pcid'].to_i == 1
    cpu += ',flags=' if spectre || pcid
    cpu += '+spec-ctrl' if spectre
    cpu += ';' if spectre && pcid
    cpu += '+pcid' if pcid
    args.delete_if { |key, value| ['cpu_type', 'spectre', 'pcid'].include?(key) || ForemanFogProxmox::Value.empty?(value) }
    args.each_value(&:to_i)
    parsed_cpu = { cpu: cpu }.merge(args)
    logger.debug("parse_server_cpu(): #{parsed_cpu}")
    parsed_cpu
  end

  def parse_server_cdrom(args)
    cdrom = args['cdrom']
    cdrom_image = args['cdrom_iso']
    volid = cdrom_image.empty? ? cdrom : cdrom_image
    return {} unless volid

    cdrom = "#{volid},media=cdrom"
    { ide2: cdrom }
  end

  def parse_server_volume(args)
    disk = {}
    id = args['id'] if args['volid'].present?
    id = "#{args['controller']}#{args['device']}" if args.key?('controller') && args.key?('device') && !id
    # FIXME: Does this make sense: return args !?
    return args if ForemanFogProxmox::Value.empty?(id) || id == 'rootfs'

    # TODO: Delete disk if requested:
    delete = args['_delete'].to_i == 1

    # ignore deleted volumes that have not been created, yet
    return nil if delete && args['volid'].blank?

    args.delete_if { |_key, value| ForemanFogProxmox::Value.empty?(value) }
    disk.store(:id, id)
    disk.store(:volid, args['volid']) if args.key?('volid')
    disk.store(:storage, args['storage'].to_s) if args.key?('storage')
    disk.store(:size, args['size'].to_i) if args.key?('size')
    options = args.reject { |key, _value| ['id', 'volid', 'controller', 'device', 'storage', 'size', '_delete'].include? key }
    disk.store(:options, options)
    logger.debug("parse_server_volume(): disk=#{disk}")
    Fog::Proxmox::DiskHelper.flatten(disk)
  end

  def parse_server_volumes(args)
    volumes = []
    args&.each_value { |value| volumes.push(parse_server_volume(value)) }
    logger.debug("parse_server_volumes(): volumes=#{volumes}")
    volumes.compact
  end

  def parse_server_interfaces(interfaces_attributes)
    interfaces_to_add = []
    interfaces_to_delete = []
    interfaces_attributes&.each_value { |value| add_server_interface(value, interfaces_to_delete, interfaces_to_add) }
    logger.debug("parse_server_interfaces(): interfaces_to_delete=#{interfaces_to_delete} interfaces_to_add=#{interfaces_to_add}")
    [interfaces_to_add, interfaces_to_delete]
  end

  def add_server_interface(interface_attributes, interfaces_to_delete, interfaces_to_add)
    interface_attributes.delete_if { |_key, value| ForemanFogProxmox::Value.empty?(value) }
    nic = {}
    id = interface_attributes['id']
    logger.debug("add_server_interface(): id=#{id}")
    delete = interface_attributes['_delete'].to_i == 1
    if delete
      interfaces_to_delete.push(id.to_s)
    else
      nic.store(:id, id)
      nic.store(:macaddr, interface_attributes['macaddr']) if interface_attributes['macaddr']
      nic.store(:tag, interface_attributes['tag'].to_i) if interface_attributes['tag']
      nic.store(:model, interface_attributes['model'].to_s)
      nic.store(:bridge, interface_attributes['bridge'].to_s) if interface_attributes['bridge']
      nic.store(:firewall, interface_attributes['firewall'].to_i) if interface_attributes['firewall']
      nic.store(:rate, interface_attributes['rate'].to_i) if interface_attributes['rate']
      nic.store(:link_down, interface_attributes['link_down'].to_i) if interface_attributes['link_down']
      nic.store(:queues, interface_attributes['queues'].to_i) if interface_attributes['queues']
      logger.debug("add_server_interface(): add nic=#{nic}")
      interfaces_to_add.push(Fog::Proxmox::NicHelper.flatten(nic))
    end
  end
end
