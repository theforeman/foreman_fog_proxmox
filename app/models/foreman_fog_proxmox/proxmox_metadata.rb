# frozen_string_literal: true

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
  module ProxmoxMetadata
    def metadata
      cache.cache(:metadata) do
        cluster_nodes = Array(nodes)
        {
          nodes: metadata_nodes(cluster_nodes),
          pools: metadata_pools,
          storages: metadata_storages(cluster_nodes),
          bridges: metadata_bridges(cluster_nodes),
          images: metadata_images,
        }
      end
    end

    private

    def metadata_nodes(cluster_nodes)
      cluster_nodes.map { |cluster_node| { node: cluster_node.node } }
    end

    def metadata_pools
      Array(pools).map do |pool|
        pool_id = pool.respond_to?(:poolid) ? pool.poolid : (pool[:poolid] || pool['poolid'])
        { poolid: pool_id }
      end
    end

    def metadata_storages(cluster_nodes)
      cluster_nodes.flat_map do |cluster_node|
        Array(storages(cluster_node.node)).map do |storage|
          data = storage.respond_to?(:as_json) ? storage.as_json : storage
          {
            storage: (data[:storage] || data['storage']),
            node_id: (data[:node_id] || data['node_id']),
            content: (data[:content] || data['content']),
            avail: (data[:avail] || data['avail']),
            used: (data[:used] || data['used']),
            total: (data[:total] || data['total']),
          }
        end
      end
    end

    def metadata_bridges(cluster_nodes)
      cluster_nodes.flat_map do |cluster_node|
        Array(bridges(cluster_node.node)).map do |bridge|
          data = bridge.respond_to?(:as_json) ? bridge.as_json : bridge
          {
            node_id: (data[:node_id] || data['node_id']),
            iface: (data[:iface] || data['iface']),
          }
        end
      end
    end

    def metadata_images
      available_images = images
      available_images = available_images.order(:name) if available_images.respond_to?(:order)

      Array(available_images).map do |image|
        data = image.respond_to?(:as_json) ? image.as_json : image
        uuid = metadata_image_value(image, data, :uuid, :id)

        {
          uuid: uuid,
          name: metadata_image_value(image, data, :name),
          disks: metadata_image_disks(uuid),
        }
      end
    end

    def metadata_image_disks(uuid)
      return nil unless uuid && respond_to?(:find_vm_by_uuid)

      find_vm_by_uuid(uuid)&.disks
    rescue ActiveRecord::RecordNotFound, StandardError
      nil
    end

    def metadata_image_value(image, data, *keys)
      keys.each do |key|
        value = [image.try(key), data.try(:[], key), data.try(:[], key.to_s)].find(&:present?)
        return value if value.present?
      end

      nil
    end
  end
end
