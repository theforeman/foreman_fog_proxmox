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

module ProxmoxContainerHelper
  def config_keys
    general_a = ['node_id', 'name', 'type', 'config_attributes', 'volumes_attributes', 'interfaces_attributes']
    general_a += ['firmware_type', 'provision_method', 'container_volumes', 'server_volumes', 'start_after_create']
    keys = { general: general_a }
    logger.debug("config_keys[:general]: #{keys[:general]}")
    keys.store(:main, ['name', 'type', 'node_id', 'vmid', 'interfaces', 'mount_points', 'disks'])
    keys.store(:cpu, ['arch', 'cpulimit', 'cpuunits', 'cores'])
    keys.store(:memory, ['memory', 'swap'])
    keys
  end

  def ostemplate_keys
    ['ostemplate', 'ostemplate_storage', 'ostemplate_file']
  end

  def parse_ostemplate_without_keys(args)
    parse_container_ostemplate(args.select { |key, _value| ostemplate_keys.include? key })
  end

  def config_general_or_ostemplate_key?(key)
    config_keys[:general].include?(key) || ostemplate_keys.include?(key)
  end

  def parse_container_vm(args)
    logger.debug("parse_container_vm args=#{args}")
    args = ActiveSupport::HashWithIndifferentAccess.new(args)
    return {} unless args
    return {} if args.empty?
    return {} unless args['type'] == 'lxc'

    parsed_vm = args.reject { |key, value| config_general_or_ostemplate_key?(key) || ForemanFogProxmox::Value.empty?(value) }
    parsed_vm = parsed_config(args, parsed_vm)
    parsed_vm = parsed_interfaces(args, parsed_vm)
    parsed_vm = parsed_volumes(args, parsed_vm)
    logger.debug("parse_container_vm(): #{parsed_vm}")
    parsed_vm
  end

  def parsed_config(args, parsed_vm)
    config = args['config_attributes']
    config ||= ForemanFogProxmox::Value.new_hash_reject_keys(args, config_keys[:main])
    cpu = parse_container_cpu(config.select { |key, _value| config_keys[:cpu].include? key })
    memory = parse_container_memory(config.select { |key, _value| config_keys[:memory].include? key })
    parsed_config = config.reject { |key, value| config_keys.include?(key) || ForemanFogProxmox::Value.empty?(value) }
    logger.debug("parse_container_config(): #{parsed_config}")
    parsed_vm.merge(parsed_config).merge(cpu).merge(memory).merge(parse_ostemplate(args, config))
  end

  def parsed_interfaces(args, parsed_vm)
    interfaces_to_add, interfaces_to_delete = parse_container_interfaces(args['interfaces_attributes'])
    interfaces_to_add.each { |interface| parsed_vm = parsed_vm.merge(interface) }
    parsed_vm = parsed_vm.merge(delete: interfaces_to_delete.join(',')) unless interfaces_to_delete.empty?
    parsed_vm
  end

  def parsed_volumes(args, parsed_vm)
    volumes = parse_container_volumes(args['volumes_attributes'])
    volumes.each { |volume| parsed_vm = parsed_vm.merge(volume) }
    parsed_vm
  end

  def parse_ostemplate(args, config)
    ostemplate = parse_ostemplate_without_keys(args)
    ostemplate = parse_ostemplate_without_keys(config) unless ostemplate[:ostemplate]
    ostemplate
  end

  def parse_container_memory(args)
    memory = {}
    ForemanFogProxmox::HashCollection.remove_empty_values(args)
    memory.store(:memory, args['memory'].to_i) if args['memory']
    memory.store(:swap, args['swap'].to_i) if args['swap']
    logger.debug("parse_container_memory(): #{memory}")
    memory
  end

  def parse_container_cpu(args)
    cpu = {}
    ForemanFogProxmox::HashCollection.remove_empty_values(args)
    cpu.store(:arch, args['arch'].to_s) if args['arch']
    cpu.store(:cpulimit, args['cpulimit'].to_i) if args['cpulimit']
    cpu.store(:cpuunits, args['cpuunits'].to_i) if args['cpuunits']
    cpu.store(:cores, args['cores'].to_i) if args['cores']
    logger.debug("parse_container_cpu(): #{cpu}")
    cpu
  end

  def parse_container_ostemplate(args)
    ostemplate = args['ostemplate']
    ostemplate_file = args['ostemplate_file']
    ostemplate ||= ostemplate_file
    ostemplate_storage = args['ostemplate_storage']
    ostemplate_storage, ostemplate_file, _size = Fog::Proxmox::DiskHelper.extract_storage_volid_size(ostemplate) unless ForemanFogProxmox::Value.empty?(ostemplate)
    parsed_ostemplate = { ostemplate: ostemplate, ostemplate_file: ostemplate_file, ostemplate_storage: ostemplate_storage }
    logger.debug("parse_container_ostemplate(): #{parsed_ostemplate}")
    parsed_ostemplate
  end

  def parse_container_volume(args)
    disk = {}
    id = args['id']
    id = "mp#{args['device']}" if args.key?('device')
    logger.debug("parse_container_volume() args=#{args}")
    return args if ForemanFogProxmox::Value.empty?(id) || Fog::Proxmox::DiskHelper.server_disk?(id)

    args.delete_if { |_key, value| ForemanFogProxmox::Value.empty?(value) }
    disk.store(:id, id)
    disk.store(:volid, args['volid'])
    disk.store(:storage, args['storage'].to_s)
    disk.store(:size, args['size'].to_i)
    options = ForemanFogProxmox::HashCollection.new_hash_reject_keys(args, ['id', 'volid', 'device', 'storage', 'size', '_delete'])
    disk.store(:options, options)
    logger.debug("parse_container_volume(): disk=#{disk}")
    Fog::Proxmox::DiskHelper.flatten(disk)
  end

  def parse_container_volumes(args)
    logger.debug("parse_container_volumes() args=#{args}")
    volumes = []
    args&.each_value { |value| volumes.push(parse_container_volume(value)) }
    logger.debug("parse_container_volumes(): volumes=#{volumes}")
    volumes
  end

  def parse_container_interfaces(interfaces_attributes)
    interfaces_to_add = []
    interfaces_to_delete = []
    interfaces_attributes&.each_value { |value| add_container_interface(value, interfaces_to_delete, interfaces_to_add) }
    logger.debug("parse_container_interfaces(): interfaces_to_add=#{interfaces_to_add}, interfaces_to_delete=#{interfaces_to_delete}")
    [interfaces_to_add, interfaces_to_delete]
  end

  def add_nic_element(nic, key, interface_attributes_key, format = :to_s)
    nic[key] = interface_attributes[interface_attributes_key].send(format) if interface_attributes[interface_attributes_key]
  end

  def add_container_interface(interface_attributes, interfaces_to_delete, interfaces_to_add)
    ForemanFogProxmox::HashCollection.remove_empty_values(interface_attributes)
    nic = {}
    id = interface_attributes['id']
    logger.debug("parse_container_interface(): id=#{id}")
    delete = interface_attributes['_delete'].to_i == 1
    if delete
      interfaces_to_delete.push(id.to_s)
    else
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :id, interface_attributes, 'id')
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :hwaddr, interface_attributes, 'macaddr')
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :name, interface_attributes, 'name')
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :bridge, interface_attributes, 'bridge')
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :ip, interface_attributes, 'ip')
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :bridge, interface_attributes, 'bridge')
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :ip6, interface_attributes, 'ip6')
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :gw, interface_attributes, 'gw')
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :gw6, interface_attributes, 'gw6')
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :rate, interface_attributes, 'rate', :to_i)
      ForemanFogProxmox::HashCollection.add_and_format_element(nic, :tag, interface_attributes, 'tag', :to_i)
      logger.debug("parse_container_interface(): add nic=#{nic}")
      interfaces_to_add.push(Fog::Proxmox::NicHelper.flatten(nic))
    end
  end
end
