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
require 'foreman_fog_proxmox/hash_collection'

module ForemanFogProxmox
  module ProxmoxVolumes
    include ProxmoxVMHelper

    def delete_volume(vm, id, volume_attributes)
      logger.info("vm #{vm.identity} delete volume #{id}")
      vm.detach(id)
      return unless volume_type?(volume_attributes, 'hard_disk')

      device = Fog::Proxmox::DiskHelper.extract_device(id)
      vm.detach('unused' + device.to_s)
    end

    def volume_options(vm, id, volume_attributes)
      options = {}
      options.store(:mp, volume_attributes['mp']) if vm.container? && id != 'rootfs'
      options.store(:cache, volume_attributes['cache']) unless vm.container? || volume_attributes['cache'].empty?
      options
    end

    def update_volume_required?(old_volume_attributes, new_volume_attributes)
      old_h = ForemanFogProxmox::HashCollection.new_hash_reject_empty_values(old_volume_attributes)
      new_h = ForemanFogProxmox::HashCollection.new_hash_reject_empty_values(new_volume_attributes)
      new_h = ForemanFogProxmox::HashCollection.new_hash_reject_keys(new_h, ['cdrom', 'cloudinit', 'storage_type'])
      !ForemanFogProxmox::HashCollection.equals?(old_h.with_indifferent_access, new_h.with_indifferent_access)
    end

    def update_cdrom(vm, disk, volume_attributes)
      new_disk = { id: disk.id }
      if ['none', 'cdrom'].include?(volume_attributes[:cdrom])
        new_disk[:volid] = volume_attributes[:cdrom]
      else
        new_disk[:storage] = volume_attributes[:storage]
        new_disk[:volid] = volume_attributes[:volid]
      end
      vm.attach(new_disk, {})
    end

    def extend_volume(vm, id, diff_size)
      extension = "+#{diff_size}G"
      logger.info("vm #{vm.identity} extend volume #{id} to #{extension}")
      vm.extend(id, extension)
    end

    def move_volume(id, vm, new_storage)
      logger.info("vm #{vm.identity} move volume #{id} into #{new_storage}")
      vm.move(id, new_storage)
    end

    def update_options(disk, vm, volume_attributes)
      options = volume_options(vm, disk.id, volume_attributes) if volume_type?(volume_attributes, 'hard_disk')
      logger.info("vm #{vm.identity} update volume #{disk.id} to #{options}")
      new_disk = { id: disk.id }
      new_disk[:volid] = disk.volid
      vm.attach(new_disk, options)
    end

    def update_volume(vm, disk, volume_attributes)
      id = disk.id
      if volume_type?(volume_attributes, 'cdrom')
        update_cdrom(vm, disk, volume_attributes)
      elsif volume_type?(volume_attributes, 'hard_disk')
        diff_size = volume_attributes['size'].to_i - disk.size.to_i if volume_attributes['size'] && disk.size
        unless diff_size >= 0
          raise ::Foreman::Exception,
            format(_('Unable to shrink %<id>s size. Proxmox allows only increasing size.'), id: id)
        end
        diff_size = volume_attributes['size'].to_i - disk.size.to_i if volume_attributes['size'] && disk.size
        raise ::Foreman::Exception, format(_('Unable to shrink %<id>s size. Proxmox allows only increasing size.'), id: id) unless diff_size >= 0

        new_storage = volume_attributes['storage']

        if diff_size > 0
          extend_volume(vm, id, diff_size)
        elsif disk.storage != new_storage
          move_volume(id, vm, new_storage)
        else
          update_options(disk, vm, volume_attributes)
        end
      end
    end

    def volume_exists?(vm, volume_attributes)
      disk = vm.config.disks.get(volume_attributes['id'])
      return false unless disk

      # Return boolean if disk of type hard_disk, cloud_init, cdrom or rootfs(LXC container) exists
      if disk.hard_disk? || disk.cloud_init? || disk.rootfs? || disk.mount_point?
        volume_attributes['volid'].present?
      elsif disk.cdrom?
        volume_attributes['cdrom'].present?
      end
    end

    def volume_to_delete?(volume_attributes)
      volume_attributes['_delete'].blank? ? false : Foreman::Cast.to_bool(volume_attributes['_delete'])
    end

    def extract_id(vm, volume_attributes)
      id = ''
      if volume_exists?(vm, volume_attributes)
        id = volume_attributes['id']
      else
        device = vm.container? ? 'mp' : volume_attributes['controller']
        id = volume_type?(volume_attributes, 'cdrom') ? 'ide2' : device + volume_attributes['device']
      end
      id
    end

    def add_volume(vm, id, volume_attributes)
      disk_attributes = { id: id }
      if volume_type?(volume_attributes, 'hard_disk')
        options = volume_options(vm, id, volume_attributes)
        disk_attributes[:storage] = volume_attributes['storage']
        disk_attributes[:size] = volume_attributes['size']
      elsif volume_type?(volume_attributes, 'cdrom')
        disk_attributes[:volid] = volume_attributes[:iso]
      elsif volume_type?(volume_attributes, 'cloud_init')
        disk_attributes[:storage] = volume_attributes['storage']
        disk_attributes[:volid] = "#{volume_attributes['storage']}:cloudinit"
      end
      logger.info("vm #{vm.identity} add volume #{id}")
      logger.debug("add_volume(#{vm.identity}) disk_attributes=#{disk_attributes}")
      vm.attach(disk_attributes, options)
    end

    def save_volume(vm, volume_attributes)
      logger.debug("save_volume(#{vm.identity}) volume_attributes=#{volume_attributes}")
      id = extract_id(vm, volume_attributes)
      if volume_exists?(vm, volume_attributes)
        if volume_to_delete?(volume_attributes)
          delete_volume(vm, id, volume_attributes)
        else
          disk = vm.config.disks.get(id)
          update_volume(vm, disk, volume_attributes) if update_volume_required?(disk.attributes, volume_attributes)
        end
      else
        add_volume(vm, id, volume_attributes)
      end
    end
  end
end
