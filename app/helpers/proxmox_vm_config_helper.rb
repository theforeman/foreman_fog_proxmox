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
require 'fog/proxmox/helpers/cpu_helper'
require 'foreman_fog_proxmox/value'
require 'foreman_fog_proxmox/hash_collection'

# Convert a foreman form server hash into a fog-proxmox server attributes hash
module ProxmoxVmConfigHelper
  KILO = 1024
  MEGA = KILO * KILO
  GIGA = KILO * MEGA

  def object_to_config_hash(vm, type)
    vm_h = ActiveSupport::HashWithIndifferentAccess.new
    main_a = ['vmid']
    main = vm.attributes.select { |key, _value| main_a.include? key }
    main_a += ['templated']
    config = vm.config.attributes.reject do |key, _value|
      main_a.include?(key) || Fog::Proxmox::DiskHelper.disk?(key) || Fog::Proxmox::NicHelper.nic?(key)
    end
    vm_h = vm_h.merge(main)
    vm_h = vm_h.merge('config_attributes': config)
    logger.debug(format('object_to_config_hash(%<type>s): vm_h=%<vm_h>s', type: type, vm_h: vm_h))
    vm_h
  end

  def convert_memory_size(config_hash, key)
    # default unit memory size is Mb
    memory = (config_hash[key].to_i / MEGA).to_s == '0' ? config_hash[key] : (config_hash[key].to_i / MEGA).to_s
    config_hash.store(key, memory)
  end

  def general_a(type)
    general_a = ['node_id', 'type', 'config_attributes', 'volumes_attributes', 'interfaces_attributes']
    general_a += ['firmware_type', 'provision_method', 'container_volumes', 'server_volumes', 'start_after_create']
    general_a += ['name'] if type == 'lxc'
    general_a
  end

  def config_typed_keys(type)
    keys = { general: general_a(type) }
    main_a = ['name', 'type', 'node_id', 'vmid', 'interfaces', 'mount_points', 'disks']
    case type
    when 'lxc'
      cpu_a = ['arch', 'cpulimit', 'cpuunits', 'cores', 'sockets']
      memory_a = ['memory', 'swap']
      ostemplate_a = ['ostemplate', 'ostemplate_storage', 'ostemplate_file']
      keys.store(:ostemplate, ostemplate_a)
    when 'qemu'
      cpu_a = ['cpu_type', 'cpu']
      cpu_a += ForemanFogProxmox::HashCollection.stringify_keys(Fog::Proxmox::CpuHelper.flags).keys
      memory_a = ['memory', 'balloon', 'shares']
      cloud_init_a = ['ciuser', 'cipassword', 'searchdomain', 'nameserver']
      keys.store(:cloud_init, cloud_init_a)
    end
    keys.store(:main, main_a)
    keys.store(:cpu, cpu_a)
    keys.store(:memory, memory_a)
    keys
  end

  def convert_memory_sizes(args)
    ['memory', 'balloon', 'shares', 'swap'].each { |key| convert_memory_size(args['config_attributes'], key) }
  end

  def config_general_or_ostemplate_key?(key)
    config_typed_keys('lxc')[:general].include?(key) || config_typed_keys(type)[:ostemplate].include?(key)
  end

  def config_a(type)
    config_a = []
    case type
    when 'qemu'
      [:cpu, :memory, :general, :cloud_init].each { |key| config_a += config_typed_keys(type)[key] }
    when 'lxc'
      [:main].each { |key| config_a += config_typed_keys(type)[key] }
    end
    config_a
  end

  def args_a(type)
    args_a = []
    case type
    when 'qemu'
      [:general].each { |key| args_a += config_typed_keys(type)[key] }
    when 'lxc'
      [:general, :ostemplate].each { |key| args_a += config_typed_keys(type)[key] }
    end
    args_a
  end

  def config_options(config, args, type)
    options = {}
    case type
    when 'qemu'
      options = config.select { |key, _value| config_typed_keys(type)[:cloud_init].include? key }
    when 'lxc'
      options = parse_ostemplate(args, config)
    end
    options
  end

  def parsed_typed_config(args, type)
    config = args['config_attributes']
    config ||= ForemanFogProxmox::HashCollection.new_hash_reject_keys(args, config_typed_keys(type)[:main])
    logger.debug("parsed_typed_config(#{type}): config=#{config}")
    config_cpu = config.select { |key, _value| config_typed_keys(type)[:cpu].include? key }
    logger.debug("parsed_typed_config(#{type}): config_cpu=#{config_cpu}")
    cpu = parse_typed_cpu(config_cpu, type)
    memory = parse_typed_memory(config.select { |key, _value| config_typed_keys(type)[:memory].include? key }, type)
    parsed_config = config.reject do |key, value|
      config_a(type).include?(key) || ForemanFogProxmox::Value.empty?(value)
    end
    parsed_vm = args.reject { |key, value| args_a(type).include?(key) || ForemanFogProxmox::Value.empty?(value) }
    parsed_vm = parsed_vm.merge(config_options(config, args, type))
    parsed_vm = parsed_vm.merge(parsed_config).merge(cpu).merge(memory)
    logger.debug("parsed_typed_config(#{type}): parsed_vm=#{parsed_vm}")
    parsed_vm
  end

  def parse_typed_memory(args, type)
    memory = {}
    ForemanFogProxmox::HashCollection.remove_empty_values(args)
    config_typed_keys(type)[:memory].each do |key|
      ForemanFogProxmox::HashCollection.add_and_format_element(memory, key.to_sym, args, key, :to_i)
    end
    memory
  end

  def parse_typed_cpu(args, type)
    cpu = {}
    ForemanFogProxmox::HashCollection.remove_empty_values(args)
    if type == 'qemu'
      logger.debug("parse_typed_cpu(#{type}): args=#{args}")
      cpu_flattened = Fog::Proxmox::CpuHelper.flatten(args)
      cpu_flattened = args[:cpu] if cpu_flattened.empty?
      logger.debug("parse_typed_cpu(#{type}): cpu_flattened=#{cpu_flattened}")
      ForemanFogProxmox::HashCollection.remove_empty_values(args)
      ForemanFogProxmox::HashCollection.remove_keys(args, config_typed_keys('qemu')[:cpu])
      args.each_value(&:to_i)
      cpu = { cpu: cpu_flattened }
    end
    if type == 'lxc'
      config_typed_keys('lxc')[:cpu].each do |key|
        ForemanFogProxmox::HashCollection.add_and_format_element(cpu, key.to_sym, args, key)
      end
    end
    logger.debug("parse_typed_cpu(#{type}): cpu=#{cpu}")
    cpu
  end
end
