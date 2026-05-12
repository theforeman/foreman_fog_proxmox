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
      cached_images = cache.cache(:"images_by_storage-#{node_id}-#{storage_id}-#{type}") do
        node = client.nodes.get node_id
        node ||= default_node
        storage = node.storages.get storage_id if storage_id
        logger.debug("images_by_storage(): node_id #{node_id} storage_id #{storage_id} type #{type}")
        if storage
          storage.volumes.list_by_content_type(type).sort_by(&:volid).map do |volume|
            {
              volid: volume.volid,
              content: volume.try(:content),
              format: volume.try(:format),
              size: volume.try(:size),
              used: volume.try(:used),
            }
          end
        end
      end

      Array(cached_images).map { |image| OpenStruct.new(image) }
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
      cached_templates = cache.cache(:templates) do
        volumes = fog_nodes.flat_map do |node|
          storages = node.storages.list_by_content_type 'images'
          logger.debug("storages(): node_id #{node.node} type images")
          storages.reject { |storage| storage.active.to_i.zero? }.sort_by(&:storage).flat_map do |storage|
            # Skip disabled storages (enabled == 0 or nil)
            unless storage.enabled.to_i == 1
              logger.warn("Skipping disabled storage #{storage.identity} on #{node.node}")
              next []
            end

            # Fetch QEMU and LXC template images
            storage.volumes.list_by_content_type('images') + storage.volumes.list_by_content_type('rootdir')
          rescue StandardError => e
            logger.error("Failed to fetch volumes for storage #{storage.identity} on #{node.node}: #{e.message}")
            []
          end
        end

        volumes.select(&:template?).map do |volume|
          {
            vmid: volume.try(:vmid),
            name: volume.try(:name),
            volid: volume.try(:volid),
            node_id: volume.try(:node_id),
            template: true,
          }
        end
      end

      Array(cached_templates).map { |template| OpenStruct.new(template) }
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
