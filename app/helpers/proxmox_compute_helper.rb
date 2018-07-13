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

module ProxmoxComputeHelper

  KILO = 1024
  MEGA = KILO * KILO
  GIGA = KILO * MEGA

  def parse_vm(args)
    return {} unless args
    return {} if args.empty?
    config = args['config_attributes']
    cdrom_a = %w[cdrom cdrom_storage cdrom_iso]
    cdrom = parse_cdrom(config.select { |key,_value| cdrom_a.include? key })
    volumes = parse_volumes(args['volumes_attributes'])
    cpu_a = %w[cpu_type spectre pcid vcpus cpulimit cpuunits cores sockets numa]
    cpu = parse_cpu(config.select { |key,_value| cpu_a.include? key })
    memory_a = %w[memory min_memory balloon shares]
    memory = parse_memory(config.select { |key,_value| memory_a.include? key })
    interfaces_attributes = args['interfaces_attributes']
    networks = parse_interfaces(interfaces_attributes)
    general_a = %w[node config_attributes volumes_attributes interfaces_attributes firmware_type provision_method]
    logger.debug("general_a: #{general_a}")
    parsed_vm = args.reject { |key,value| general_a.include?(key) || value.empty? }
    config_a = []
    config_a += cpu_a
    config_a += cdrom_a
    config_a += memory_a
    parsed_config = config.reject { |key,value| config_a.include?(key) || value.empty? }
    logger.debug("parse_config(): #{parsed_config}")
    parsed_vm = parsed_vm.merge(parsed_config).merge(cpu).merge(memory).merge(cdrom)
    networks.each { |network| parsed_vm = parsed_vm.merge(network) }
    volumes.each { |volume| parsed_vm = parsed_vm.merge(volume) }
    logger.debug("parse_vm(): #{parsed_vm}")
    parsed_vm
  end

  def parse_memory(args)
    memory = { memory: args['memory'].to_i }
    ballooned = args['balloon'].to_i == 1
    if ballooned
      memory.store(:shares,args['shares'].to_i)
      memory.store(:balloon,args['min_memory'].to_i)
    else
      memory.store(:balloon,args['balloon'].to_i)
    end
    logger.debug("parse_memory(): #{memory}")
    memory
  end

  def parse_cpu(args)
    cpu = "cputype=#{args['cpu_type']}"
    spectre = args['spectre'].to_i == 1
    pcid = args['pcid'].to_i == 1
    cpu += ",flags=" if spectre || pcid
    cpu += "+spec-ctrl" if spectre
    cpu += ";" if spectre && pcid
    cpu += "+pcid" if pcid      
    args.delete_if { |key,value| %w[cpu_type spectre pcid].include?(key) || value.empty? }
    args.each_value { |value| value.to_i }
    parsed_cpu = { cpu: cpu }.merge(args)
    logger.debug("parse_cpu(): #{parsed_cpu}")
    parsed_cpu
  end

  def parse_cdrom(args)
    cdrom = args['cdrom']
    cdrom_image = args['cdrom_iso']
    volid = cdrom_image.empty? ? cdrom : cdrom_image
    cdrom = "#{volid},media=cdrom"
    {ide2: cdrom}
  end

  def parse_volume(args)
    disk = {}
    id = args['id']
    id = "#{args['controller']}#{args['device']}" unless id
    delete = args['_delete'].to_i == 1
    args.delete_if { |_key,value| value.empty? }
    if delete
      logger.debug("parse_volume(): delete id=#{id}")
      disk.store(:delete, id)
      disk
    else
      disk.store(:id, id)
      disk.store(:volid, args['volid'])
      disk.store(:storage, args['storage'].to_s)
      disk.store(:size, args['size'])
      options = args.reject { |key,_value| %w[id volid controller device storage size _delete].include? key}
      disk.store(:options, options)
      logger.debug("parse_volume(): add disk=#{disk}")
      Fog::Proxmox::DiskHelper.flatten(disk)
    end 
  end

  def parse_volumes(args)
    volumes = []
    args.each_value { |value| volumes.push(parse_volume(value))} if args
    logger.debug("parse_volumes(): volumes=#{volumes}")
    volumes
  end

  def parse_interfaces(args)
    nics = []
    args.each_value { |value| nics.push(parse_interface(value))} if args
    logger.debug("parse_interfaces(): nics=#{nics}")
    nics
  end

  def parse_interface(args)
    args.delete_if { |_key,value| value.empty? }
    nic = {}
    id = args['id']
    logger.debug("parse_interface(): id=#{id}")
    delete = args['_delete'].to_i == 1
    if delete
      logger.debug("parse_interface(): delete id=#{id}")
      nic.store(:delete, id)
      nic
    else
      nic.store(:id, id)
      nic.store(:tag, args['vlan'].to_i) if args['vlan']
      nic.store(:model, args['model'].to_s)
      nic.store(:bridge, args['bridge'].to_s) if args['bridge']
      nic.store(:firewall, args['firewall'].to_i) if args['firewall']
      nic.store(:rate, args['rate'].to_i) if args['rate']
      nic.store(:link_down, args['disconnect'].to_i) if args['disconnect']
      nic.store(:queues, args['queues'].to_i) if args['queues']
      logger.debug("parse_interface(): add nic=#{nic}")
      Fog::Proxmox::NicHelper.flatten(nic)
    end 
  end

end