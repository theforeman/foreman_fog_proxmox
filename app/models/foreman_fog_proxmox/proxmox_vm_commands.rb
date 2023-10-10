# frozen_string_literal: true

# Copyright 2019 Tristan Robert

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

require 'foreman_fog_proxmox/hash_collection'

module ForemanFogProxmox
  module ProxmoxVmCommands
    include ProxmoxVolumes
    include ProxmoxPools
    include ProxmoxVmHelper

    def start_on_boot(vm, args)
      startonboot = args[:start_after_create].blank? ? false : Foreman::Cast.to_bool(args[:start_after_create])
      vm.start if startonboot
      vm
    end

    def create_vm(args = {})
      vmid = args[:vmid].to_i
      type = args[:type]
      node = client.nodes.get(args[:node_id])
      vmid = node.servers.next_id.to_i if vmid < 1
      raise ::Foreman::Exception, format(N_('invalid vmid=%<vmid>s'), vmid: vmid) unless node.servers.id_valid?(vmid)

      image_id = args[:image_id]
      remove_volume_keys(args)
      if image_id
        vm = clone_from_image(image_id, vmid)
        vm.update(compute_clone_attributes(args, vm.container?, type))
        update_pool(vm, args[:pool]) if args[:pool]
      else
        logger.warn("create vm: args=#{args}")
        vm = node.send(vm_collection(type)).create(parse_typed_vm(args, type))
      end
      start_on_boot(vm, args)
    rescue StandardError => e
      logger.warn("failed to create vm: #{e}")
      destroy_vm id.to_s + '_' + vm.vmid.to_s if vm
      raise e
    end

    def compute_clone_attributes(args, container, type)
      args = parse_cloudinit_config(args) if args[:user_data]
      parsed_args = parse_typed_vm(args, type)
      if container
        options = { :hostname => args[:name] }
        parsed_args.merge(options)
      end
      parsed_args.reject { |k| k == 'pool' }
    end

    def destroy_vm(uuid)
      vm = find_vm_by_uuid(uuid)
      return true if vm.nil?
      vm.stop if vm.ready?
      vm.destroy
    rescue ActiveRecord::RecordNotFound
      # if the VM does not exists, we don't really care.
      true
    end

    def supports_update?
      true
    end

    def user_data_supported?
      true
    end

    def compute_config_attributes(parsed_attr)
      excluded_keys = [:vmid, :templated, :ostemplate, :ostemplate_file, :ostemplate_storage, :volumes_attributes,
                       :pool]
      config_attributes = parsed_attr.reject { |key, _value| excluded_keys.include? key.to_sym }
      ForemanFogProxmox::HashCollection.remove_empty_values(config_attributes)
      config_attributes = config_attributes.reject { |key, _value| Fog::Proxmox::DiskHelper.disk?(key) }
      { config_attributes: config_attributes }
    end

    def save_vm(uuid, new_attributes)
      vm = find_vm_by_uuid(uuid)
      templated = new_attributes['templated']
      node_id = new_attributes['node_id']
      if templated == '1' && !vm.templated?
        vm.create_template
      elsif vm.node_id != node_id
        vm.migrate(node_id)
      else
        parsed_attr = parse_typed_vm(
          ForemanFogProxmox::HashCollection.new_hash_reject_keys(new_attributes,
            ['volumes_attributes']).merge(type: vm.type), vm.type
        )
        config_attributes = compute_config_attributes(parsed_attr)
        volumes_attributes = new_attributes['volumes_attributes']
        logger.debug("save_vm(#{uuid}) volumes_attributes=#{volumes_attributes}")
        volumes_attributes&.each_value { |volume_attributes| save_volume(vm, volume_attributes) }
        vm.update(config_attributes[:config_attributes])
        poolid = new_attributes['pool'] if new_attributes.key?('pool')
        update_pool(vm, poolid) if poolid
      end
      find_vm_by_uuid(uuid)
    end
  end
end
