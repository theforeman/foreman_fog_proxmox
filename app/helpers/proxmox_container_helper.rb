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
    args = ActiveSupport::HashWithIndifferentAccess.new(args)
    return {} unless args
    return {} if args.empty?
    return {} unless args['type'] == 'lxc'
    config = args['config_attributes']
    main_a = %w[name type node_id vmid interfaces mount_points disks]
    config = args.reject { |key,_value| main_a.include? key } unless config
    ostemplate_a = %w[ostemplate ostemplate_storage ostemplate_file]
    ostemplate = parse_container_ostemplate(args.select { |key,_value| ostemplate_a.include? key })
    ostemplate = parse_container_ostemplate(config.select { |key,_value| ostemplate_a.include? key }) unless ostemplate[:ostemplate]
    volumes = parse_container_volumes(args['volumes_attributes'])
    cpu_a = %w[arch cpulimit cpuunits cores]
    cpu = parse_container_cpu(config.select { |key,_value| cpu_a.include? key })
    memory_a = %w[memory swap]
    memory = parse_container_memory(config.select { |key,_value| memory_a.include? key })
    interfaces_attributes = args['interfaces_attributes']
    networks = parse_container_interfaces(interfaces_attributes)
    general_a = %w[node_id name type config_attributes volumes_attributes interfaces_attributes firmware_type provision_method container_volumes server_volumes]
    logger.debug("general_a: #{general_a}")
    parsed_vm = args.reject { |key,value| general_a.include?(key) || ostemplate_a.include?(key) || ForemanFogProxmox::Value.empty?(value) }
    config_a = []
    config_a += cpu_a
    config_a += memory_a
    config_a += main_a
    config_a += general_a
    parsed_config = config.reject { |key,value| config_a.include?(key) || ForemanFogProxmox::Value.empty?(value) }
    logger.debug("parse_container_config(): #{parsed_config}")
    parsed_vm = parsed_vm.merge(parsed_config).merge(cpu).merge(memory).merge(ostemplate)
    networks.each { |network| parsed_vm = parsed_vm.merge(network) }
    volumes.each { |volume| parsed_vm = parsed_vm.merge(volume) }
    logger.debug("parse_container_vm(): #{parsed_vm}")
    parsed_vm
  end

  def parse_container_memory(args)
    memory = {} 
    args.delete_if { |_key,value| ForemanFogProxmox::Value.empty?(value) }
    memory.store(:memory, args['memory'].to_i) if args['memory']
    memory.store(:swap, args['swap'].to_i) if args['swap']
    logger.debug("parse_container_memory(): #{memory}")
    memory
  end

  def parse_container_cpu(args)
    cpu = {}
    args.delete_if { |_key,value| ForemanFogProxmox::Value.empty?(value) }
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
    ostemplate = ostemplate ? ostemplate : ostemplate_file
    ostemplate_storage = args['ostemplate_storage']
    ostemplate_storage, ostemplate_file, _size  = Fog::Proxmox::DiskHelper.extract_storage_volid_size(ostemplate) unless ForemanFogProxmox::Value.empty?(ostemplate)
    parsed_ostemplate = {ostemplate: ostemplate, ostemplate_file: ostemplate_file, ostemplate_storage: ostemplate_storage}
    logger.debug("parse_container_ostemplate(): #{parsed_ostemplate}")
    parsed_ostemplate
  end

  def parse_container_volume(args)
    disk = {}
    id = args['id']
    id = "mp#{args['device']}" if args.has_key?('device') && !id
    delete = args['_delete'].to_i == 1
    logger.debug("parse_container_volume() args=#{args}")
    return args if ForemanFogProxmox::Value.empty?(id) || server_disk?(id)
    args.delete_if { |_key,value| ForemanFogProxmox::Value.empty?(value) }
    if delete
      logger.debug("parse_container_volume(): delete id=#{id}")
      disk.store(:delete, id)
      disk
    else
      disk.store(:id, id)
      disk.store(:volid, args['volid'])
      disk.store(:storage, args['storage'].to_s)
      disk.store(:size, args['size'].to_i)
      options = args.reject { |key,_value| %w[id volid device storage size _delete].include? key}
      disk.store(:options, options)
      logger.debug("parse_container_volume(): add disk=#{disk}")
      Fog::Proxmox::DiskHelper.flatten(disk)
    end 
  end

  def parse_container_volumes(args)
    logger.debug("parse_container_volumes() args=#{args}")
    volumes = []
    args.each_value { |value| volumes.push(parse_container_volume(value))} if args
    logger.debug("parse_container_volumes(): volumes=#{volumes}")
    volumes
  end

  def parse_container_interfaces(args)
    nics = []
    args.each_value { |value| nics.push(parse_container_interface(value))} if args
    logger.debug("parse_container_interfaces(): nics=#{nics}")
    nics
  end

  def parse_container_interface(args)
    args.delete_if { |_key,value| ForemanFogProxmox::Value.empty?(value) }
    nic = {}
    id = args['id']
    logger.debug("parse_container_interface(): id=#{id}")
    delete = args['_delete'].to_i == 1
    if delete
      logger.debug("parse_container_interface(): delete id=#{id}")
      nic.store(:delete, id)
      nic
    else
      nic.store(:id, id)
      nic.store(:name, args['name'].to_s)
      nic.store(:bridge, args['bridge'].to_s) if args['bridge']
      nic.store(:ip, args['ip'].to_s) if args['ip']
      nic.store(:ip6, args['ip6'].to_s) if args['ip6']
      nic.store(:rate, args['rate'].to_i) if args['rate']
      nic.store(:tag, args['tag'].to_i) if args['tag']
      logger.debug("parse_container_interface(): add nic=#{nic}")
      Fog::Proxmox::NicHelper.container_flatten(nic)
    end 
  end

end