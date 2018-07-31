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

module ProxmoxContainerHelper

  KILO = 1024
  MEGA = KILO * KILO
  GIGA = KILO * MEGA

  def parse_container_vm(args)
    return {} unless args
    return {} if args.empty?
    return {} unless args['type'] == 'lxc'
    config = args['config_attributes']
    ostemplate_a = %w[ostemplate_storage ostemplate_file]
    ostemplate = parse_container_ostemplate(config.select { |key,_value| ostemplate_a.include? key })
    volumes = parse_container_volumes(args['volumes_attributes'])
    cpu_a = %w[arch cpulimit cpuunits cores]
    cpu = parse_container_cpu(config.select { |key,_value| cpu_a.include? key })
    memory_a = %w[memory swap]
    memory = parse_container_memory(config.select { |key,_value| memory_a.include? key })
    interfaces_attributes = args['interfaces_attributes']
    networks = parse_container_interfaces(interfaces_attributes)
    general_a = %w[node config_attributes volumes_attributes interfaces_attributes firmware_type provision_method]
    logger.debug("general_a: #{general_a}")
    parsed_vm = args.reject { |key,value| general_a.include?(key) || value.empty? }
    config_a = []
    config_a += cpu_a
    config_a += ostemplate_a
    config_a += memory_a
    parsed_config = config.reject { |key,value| config_a.include?(key) || value.empty? }
    logger.debug("parse_container_config(): #{parsed_config}")
    parsed_vm = parsed_vm.merge(parsed_config).merge(cpu).merge(memory).merge(ostemplate)
    networks.each { |network| parsed_vm = parsed_vm.merge(network) }
    volumes.each { |volume| parsed_vm = parsed_vm.merge(volume) }
    logger.debug("parse_container_vm(): #{parsed_vm}")
    parsed_vm
  end

  def parse_container_memory(args)
    memory = { memory: args['memory'].to_i, swap: args['swap'].to_i }
    logger.debug("parse_container_memory(): #{memory}")
    memory
  end

  def parse_container_cpu(args)
    cpu = "arch=#{args['arch']}"
    args.delete_if { |key,value| %w[arch].include?(key) || value.empty? }
    args.each_value { |value| value.to_i }
    parsed_cpu = { cpu: cpu }.merge(args)
    logger.debug("parse_container_cpu(): #{parsed_cpu}")
    parsed_cpu
  end

  def parse_container_ostemplate(args)
    ostemplate_storage = args['ostemplate_storage']
    ostemplate_file = args['ostemplate_file']
    volid = "#{ostemplate_storage}:#{ostemplate_file}"
    {ostemplate: volid}
  end

  def parse_container_volume(args)
    disk = {}
    id = args['id']
    id = "mp#{args['device']}" unless id
    delete = args['_delete'].to_i == 1
    args.delete_if { |_key,value| value.empty? }
    if delete
      logger.debug("parse_container_volume(): delete id=#{id}")
      disk.store(:delete, id)
      disk
    else
      disk.store(:id, id)
      disk.store(:volid, args['volid'])
      disk.store(:storage, args['storage'].to_s)
      disk.store(:size, args['size'])
      options = args.reject { |key,_value| %w[id volid device storage size _delete].include? key}
      disk.store(:options, options)
      logger.debug("parse_container_volume(): add disk=#{disk}")
      Fog::Proxmox::DiskHelper.flatten(disk)
    end 
  end

  def parse_container_volumes(args)
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
    args.delete_if { |_key,value| value.empty? }
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
      nic.store(:link_down, args['disconnect'].to_i) if args['disconnect']
      nic.store(:queues, args['queues'].to_i) if args['queues']
      logger.debug("parse_container_interface(): add nic=#{nic}")
      Fog::Proxmox::NicHelper.flatten(nic)
    end 
  end

end