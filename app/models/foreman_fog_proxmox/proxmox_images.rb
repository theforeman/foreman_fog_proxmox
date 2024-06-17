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

    def images_by_storage(node_id, storage_id, type = 'iso')
      node = client.nodes.get node_id
      node ||= default_node
      storage = node.storages.get storage_id if storage_id
      logger.debug("images_by_storage(): node_id #{node_id} storage_id #{storage_id} type #{type}")
      storage.volumes.list_by_content_type(type).sort_by(&:volid) if storage
    end

    def template_name(template)
      image = find_vm_by_uuid(template_uuid(template))
      image&.name
    end

    def template_uuid(template)
      id.to_s + '_' + template.vmid.to_s
    end

    def available_images
      templates.collect { |template| OpenStruct.new(id: template_uuid(template), name: template_name(template)) }
    end

    def templates
      volumes = []
      nodes.each do |node|
        storages(node.node).each do |storage|
          # fetches volumes of QEMU servers for images
          volumes += storage.volumes.list_by_content_type('images')

          # fetches volumes of KVM containers for images
          volumes += storage.volumes.list_by_content_type('rootdir')
        end
      end
      # for creating image, only list volumes which are templated
      volumes.select(&:template?)
    end

    def template(uuid)
      find_vm_by_uuid(uuid)
    end

    def clone_from_image(image_id, vmid)
      logger.debug("create_vm(): clone #{image_id} in #{vmid}")
      image = find_vm_by_uuid(image_id)
      image.clone(vmid)
      find_vm_by_uuid(id.to_s + '_' + vmid.to_s)
    end
  end
end
