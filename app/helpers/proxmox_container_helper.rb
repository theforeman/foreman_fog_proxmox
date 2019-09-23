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

module ProxmoxContainerHelper
  KILO = 1024
  MEGA = KILO * KILO
  GIGA = KILO * MEGA

  def parse_container_vm(args)
    logger.debug("parse_container_vm args=#{args}")
    args = ActiveSupport::HashWithIndifferentAccess.new(args)
    return {} unless args
    return {} if args.empty?
    return {} unless args['type'] == 'lxc'

    config = args['config_attributes']
    main_a = ['name', 'type', 'node_id', 'vmid', 'interfaces', 'mount_points', 'disks']
    config ||= args.reject { |key, _value| main_a.include? key }
    ostemplate_a = ['ostemplate', 'ostemplate_storage', 'ostemplate_file']
    ostemplate = parse_container_ostemplate(args.select { |key, _value| ostemplate_a.include? key })
    ostemplate = parse_container_ostemplate(config.select { |key, _value| ostemplate_a.include? key }) unless ostemplate[:ostemplate]
    volumes = parse_container_volumes(args['volumes_attributes'])
    cpu_a = ['arch', 'cpulimit', 'cpuunits', 'cores']
    cpu = parse_container_cpu(config.select { |key, _value| cpu_a.include? key })
    memory_a = ['memory', 'swap']
    memory = parse_container_memory(config.select { |key, _value| memory_a.include? key })
    interfaces_attributes = args['interfaces_attributes']
    interfaces_to_add, interfaces_to_delete = parse_container_interfaces(interfaces_attributes)
    general_a = ['node_id', 'name', 'type', 'config_attributes', 'volumes_attributes', 'interfaces_attributes', 'firmware_type', 'provision_method', 'container_volumes', 'server_volumes']
    logger.debug("general_a: #{general_a}")
    parsed_vm = args.reject { |key, value| general_a.include?(key) || ostemplate_a.include?(key) || ForemanFogProxmox::Value.empty?(value) }
    config_a = []
    config_a += cpu_a
    config_a += memory_a
    config_a += main_a
    config_a += general_a
    parsed_config = config.reject { |key, value| config_a.include?(key) || ForemanFogProxmox::Value.empty?(value) }
    logger.debug("parse_container_config(): #{parsed_config}")
    parsed_vm = parsed_vm.merge(parsed_config).merge(cpu).merge(memory).merge(ostemplate)
    interfaces_to_add.each { |interface| parsed_vm = parsed_vm.merge(interface) }
    parsed_vm = parsed_vm.merge(delete: interfaces_to_delete.join(',')) unless interfaces_to_delete.empty?
    volumes.each { |volume| parsed_vm = parsed_vm.merge(volume) }
    logger.debug("parse_container_vm(): #{parsed_vm}")
    parsed_vm
  end

  def parse_container_memory(args)
    memory = {}
    args.delete_if { |_key, value| ForemanFogProxmox::Value.empty?(value) }
    memory.store(:memory, args['memory'].to_i) if args['memory']
    memory.store(:swap, args['swap'].to_i) if args['swap']
    logger.debug("parse_container_memory(): #{memory}")
    memory
  end

  def parse_container_cpu(args)
    cpu = {}
    args.delete_if { |_key, value| ForemanFogProxmox::Value.empty?(value) }
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
    options = args.reject { |key, _value| ['id', 'volid', 'device', 'storage', 'size', '_delete'].include? key }
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

  def add_container_interface(interface_attributes, interfaces_to_delete, interfaces_to_add)
    interface_attributes.delete_if { |_key, value| ForemanFogProxmox::Value.empty?(value) }
    nic = {}
    id = interface_attributes['id']
    logger.debug("parse_container_interface(): id=#{id}")
    delete = interface_attributes['_delete'].to_i == 1
    if delete
      interfaces_to_delete.push(id.to_s)
    else
      nic.store(:id, id)
      nic.store(:macaddr, interface_attributes['macaddr']) if interface_attributes['macaddr']
      nic.store(:name, interface_attributes['name'].to_s)
      nic.store(:bridge, interface_attributes['bridge'].to_s) if interface_attributes['bridge']
      nic.store(:ip, interface_attributes['ip'].to_s) if interface_attributes['ip']
      nic.store(:ip6, interface_attributes['ip6'].to_s) if interface_attributes['ip6']
      nic.store(:rate, interface_attributes['rate'].to_i) if interface_attributes['rate']
      nic.store(:tag, interface_attributes['tag'].to_i) if interface_attributes['tag']
      logger.debug("parse_container_interface(): add nic=#{nic}")
      interfaces_to_add.push(Fog::Proxmox::NicHelper.flatten(nic))
    end
  end
end
