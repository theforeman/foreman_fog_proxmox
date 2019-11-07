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
  module ProxmoxImages
    def image_exists?(image)
      !find_vm_by_uuid(image).nil?
    end

    def images_by_storage(storage_id, type = 'iso')
      storage = node.storages.get storage_id if storage_id
      storage.volumes.list_by_content_type(type).sort_by(&:volid) if storage
    end

    def available_images
      templates.collect { |template| OpenStruct.new(id: template.vmid) }
    end

    def templates
      storage = storages.first
      images = storage.volumes.list_by_content_type('images')
      images.select(&:templated?)
    end

    def template(vmid)
      find_vm_by_uuid(vmid)
    end

    def clone_from_image(image_id, args, vmid)
      logger.debug(format(_('create_vm(): clone %<image_id>s in %<vmid>s'), image_id: image_id, vmid: vmid))
      image = node.servers.get image_id
      image.clone(vmid)
      clone = node.servers.get vmid
      clone.update(name: args[:name])
    end
  end
end
