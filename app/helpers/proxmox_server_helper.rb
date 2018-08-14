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
    args = ActiveSupport::HashWithIndifferentAccess.new(args)
    return {} unless args
    return {} if args.empty?
    return {} unless args['type'] == 'qemu'
    config = args['config_attributes']
    main_a = %w[name type node vmid]
    config = args.reject { |key,_value| main_a.include? key } unless config
    cdrom_a = %w[cdrom cdrom_storage cdrom_iso]
    cdrom = parse_server_cdrom(config.select { |key,_value| cdrom_a.include? key })
    vols = args['volumes_attributes']
    volumes = parse_server_volumes(vols)
    cpu_a = %w[cpu_type spectre pcid vcpus cpulimit cpuunits cores sockets numa]
    cpu = parse_server_cpu(config.select { |key,_value| cpu_a.include? key })
    memory_a = %w[memory min_memory balloon shares]
    memory = parse_server_memory(config.select { |key,_value| memory_a.include? key })
    interfaces_attributes = args['interfaces_attributes']
    networks = parse_server_interfaces(interfaces_attributes)
    general_a = %w[node type config_attributes volumes_attributes interfaces_attributes firmware_type provision_method container_volumes server_volumes]
    logger.debug("general_a: #{general_a}")
    parsed_vm = args.reject { |key,value| general_a.include?(key) || ForemanFogProxmox::Value.empty?(value) }
    config_a = []
    config_a += cpu_a
    config_a += cdrom_a
    config_a += memory_a
    config_a += general_a
    parsed_config = config.reject { |key,value| config_a.include?(key) || ForemanFogProxmox::Value.empty?(value) }
    logger.debug("parse_server_config(): #{parsed_config}")
    parsed_vm = parsed_vm.merge(parsed_config).merge(cpu).merge(memory).merge(cdrom)
    networks.each { |network| parsed_vm = parsed_vm.merge(network) }
    volumes.each { |volume| parsed_vm = parsed_vm.merge(volume) }
    logger.debug("parse_server_vm(): #{parsed_vm}")
    parsed_vm
  end

  def parse_server_memory(args)
    memory = { memory: args['memory'].to_i }
    ballooned = args['balloon'].to_i == 1
    if ballooned
      memory.store(:shares,args['shares'].to_i)
      memory.store(:balloon,args['min_memory'].to_i)
    else
      memory.store(:balloon,args['balloon'].to_i)
    end
    logger.debug("parse_server_memory(): #{memory}")
    memory
  end

  def parse_server_cpu(args)
    cpu = "cputype=#{args['cpu_type']}"
    spectre = args['spectre'].to_i == 1
    pcid = args['pcid'].to_i == 1
    cpu += ",flags=" if spectre || pcid
    cpu += "+spec-ctrl" if spectre
    cpu += ";" if spectre && pcid
    cpu += "+pcid" if pcid      
    args.delete_if { |key,value| %w[cpu_type spectre pcid].include?(key) || ForemanFogProxmox::Value.empty?(value) }
    args.each_value { |value| value.to_i }
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
    {ide2: cdrom}
  end

  def parse_server_volume(args)
    disk = {}
    id = args['id']
    id = "#{args['controller']}#{args['device']}" unless id
    return args if ForemanFogProxmox::Value.empty?(id)
    delete = args['_delete'].to_i == 1
    args.delete_if { |_key,value| ForemanFogProxmox::Value.empty?(value) }
    if delete
      logger.debug("parse_server_volume(): delete id=#{id}")
      disk.store(:delete, id)
      disk
    else
      disk.store(:id, id)
      disk.store(:volid, args['volid'])
      disk.store(:storage, args['storage'].to_s)
      disk.store(:size, args['size'].to_i)
      options = args.reject { |key,_value| %w[id volid controller device storage size _delete].include? key}
      disk.store(:options, options)
      logger.debug("parse_server_volume(): add disk=#{disk}")
      Fog::Proxmox::DiskHelper.flatten(disk)
    end 
  end

  def parse_server_volumes(args)
    volumes = []
    args.each_value { |value| volumes.push(parse_server_volume(value))} if args
    logger.debug("parse_server_volumes(): volumes=#{volumes}")
    volumes
  end

  def parse_server_interfaces(args)
    nics = []
    args.each_value { |value| nics.push(parse_server_interface(value))} if args
    logger.debug("parse_server_interfaces(): nics=#{nics}")
    nics
  end

  def parse_server_interface(args)
    args.delete_if { |_key,value| ForemanFogProxmox::Value.empty?(value) }
    nic = {}
    id = args['id']
    logger.debug("parse_server_interface(): id=#{id}")
    delete = args['_delete'].to_i == 1
    if delete
      logger.debug("parse_server_interface(): delete id=#{id}")
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
      logger.debug("parse_server_interface(): add nic=#{nic}")
      Fog::Proxmox::NicHelper.flatten(nic)
    end 
  end

end