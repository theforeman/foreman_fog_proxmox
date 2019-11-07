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

require 'fog/proxmox/helpers/disk_helper'

module ForemanFogProxmox
  module ProxmoxVolumes
    include ProxmoxVmHelper

    def delete_volume(vm, id)
      vm.detach(id)
      device = Fog::Proxmox::DiskHelper.extract_device(id)
      vm.detach('unused' + device.to_s)
    end

    def extend_or_move_volume(vm, id, volume_attributes)
      disk = vm.config.disks.get(id)
      diff_size = volume_attributes['size'].to_i - disk.size
      raise ::Foreman::Exception, format(_('Unable to shrink %<id>s size. Proxmox allows only increasing size.'), id: id) unless diff_size >= 0

      if diff_size > 0
        extension = '+' + (diff_size / GIGA).to_s + 'G'
        vm.extend(id, extension)
      elsif disk.storage != volume_attributes['storage']
        vm.move(id, volume_attributes['storage'])
      end
    end

    def volume_exists?(volume_attributes)
      volid = volume_attributes.key?('volid') ? volume_attributes['volid'] : ''
      volid.present?
    end

    def volume_to_delete?(volume_attributes)
      volume_attributes['_delete'].blank? ? false : Foreman::Cast.to_bool(volume_attributes['_delete'])
    end

    def extract_id(vm, volume_attributes)
      id = ''
      if volume_exists?(volume_attributes)
        id = volume_attributes['id']
      else
        device = vm.container? ? 'mp' : volume_attributes['controller']
        id = device + volume_attributes['device']
      end
      id
    end

    def add_volume(vm, id, volume_attributes)
      options = {}
      options.store(:mp, volume_attributes['mp']) if vm.container?
      disk_attributes = { id: id, storage: volume_attributes['storage'], size: (volume_attributes['size'].to_i / GIGA).to_s }
      vm.attach(disk_attributes, options)
    end

    def save_volume(vm, volume_attributes)
      id = extract_id(vm, volume_attributes)
      if volume_exists?(volume_attributes)
        if volume_to_delete?(volume_attributes)
          delete_volume(vm, id)
        else
          extend_or_move_volume(vm, id, volume_attributes)
        end
      else
        add_volume(vm, id, volume_attributes)
      end
    end
  end
end
