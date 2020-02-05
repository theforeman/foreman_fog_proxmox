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

module ForemanFogProxmox
  module ProxmoxVmCommands
    include ProxmoxVolumes

    def start_on_boot(vm, args)
      startonboot = args[:config_attributes][:onboot].blank? ? false : Foreman::Cast.to_bool(args[:config_attributes][:onboot])
      vm.start if startonboot
      vm
    end

    def create_vm(args = {})
      vmid = args[:vmid].to_i
      type = args[:type]
      node = client.nodes.get(args[:node_id])
      raise ::Foreman::Exception, format(N_('invalid vmid=%<vmid>s'), vmid: vmid) unless node.servers.id_valid?(vmid)

      image_id = args[:image_id]
      if image_id
        clone_from_image(image_id, args, vmid)
      else
        convert_sizes(args)
        remove_deletes(args)
        case type
        when 'qemu'
          vm = node.servers.create(parse_server_vm(args))
        when 'lxc'
          hash = parse_container_vm(args)
          hash = hash.merge(vmid: vmid)
          vm = node.containers.create(hash.reject { |key, _value| ['ostemplate_storage', 'ostemplate_file'].include? key })
        end
        start_on_boot(vm, args)
      end
    rescue StandardError => e
      logger.warn(format(_('failed to create vm: %<e>s'), e: e))
      destroy_vm vm.id if vm
      raise e
    end

    def destroy_vm(uuid)
      vm = find_vm_by_uuid(uuid)
      vm.stop if vm.ready?
      vm.destroy
    rescue ActiveRecord::RecordNotFound
      # if the VM does not exists, we don't really care.
      true
    end

    def supports_update?
      true
    end

    def update_required?(old_attrs, new_attrs)
      return true if super(old_attrs, new_attrs)

      new_attrs[:interfaces_attributes]&.each do |key, interface|
        return true if (interface[:id].blank? || interface[:_delete] == '1') && key != 'new_interfaces' # ignore the template
      end

      new_attrs[:volumes_attributes]&.each do |key, volume|
        return true if (volume[:id].blank? || volume[:_delete] == '1') && key != 'new_volumes' # ignore the template
      end

      false
    end

    def user_data_supported?
      true
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
        convert_memory_sizes(new_attributes)
        volumes_attributes = new_attributes['volumes_attributes']
        volumes_attributes&.each_value { |volume_attributes| save_volume(vm, volume_attributes) }
        parsed_attr = vm.container? ? parse_container_vm(new_attributes.merge(type: vm.type)) : parse_server_vm(new_attributes.merge(type: vm.type))
        logger.debug("parsed_attr=#{parsed_attr}")
        config_attributes = parsed_attr.reject { |key, _value| [:vmid, :templated, :ostemplate, :ostemplate_file, :ostemplate_storage, :volumes_attributes].include? key.to_sym }
        config_attributes = config_attributes.reject { |_key, value| ForemanFogProxmox::Value.empty?(value) }
        cdrom_attributes = parsed_attr.select { |_key, value| Fog::Proxmox::DiskHelper.cdrom?(value.to_s) }
        config_attributes = config_attributes.reject { |key, _value| Fog::Proxmox::DiskHelper.disk?(key) }
        vm.update(config_attributes.merge(cdrom_attributes))
        start_on_boot(vm, new_attributes)
      end
      find_vm_by_uuid(uuid)
    end
  end
end
