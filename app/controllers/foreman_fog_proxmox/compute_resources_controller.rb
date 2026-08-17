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

module ForemanFogProxmox
  class ComputeResourcesController < ::ApplicationController
    # GET foreman_fog_proxmox/isos/:compute_resource_id/:node_id/:storage
    def isos_by_id_and_node_and_storage
      volumes = load_compute_resource(params[:compute_resource_id]).images_by_storage(params[:node_id],
        params[:storage], 'iso')
      respond_to do |format|
        format.json { render :json => volumes }
      end
    end

    # GET foreman_fog_proxmox/ostemplates/:compute_resource_id/:node_id/:storage
    def ostemplates_by_id_and_node_and_storage
      volumes = load_compute_resource(params[:compute_resource_id]).images_by_storage(params[:node_id],
        params[:storage], 'vztmpl')
      respond_to do |format|
        format.json { render :json => volumes }
      end
    end

    # GET foreman_fog_proxmox/isos/:compute_resource_id/:node_id
    def isos_by_id_and_node
      volumes = load_compute_resource(params[:compute_resource_id]).images_by_storage(params[:node_id],
        params[:storage], 'iso')
      respond_to do |format|
        format.json { render :json => volumes }
      end
    end

    # GET foreman_fog_proxmox/ostemplates/:compute_resource_id/:node_id
    def ostemplates_by_id_and_node
      storages = load_compute_resource(params[:compute_resource_id]).storages(params[:node_id], 'vztmpl')
      respond_to do |format|
        format.json { render :json => storages }
      end
    end

    # GET foreman_fog_proxmox/storages/:compute_resource_id/:node_id
    def storages_by_id_and_node
      storages = load_compute_resource(params[:compute_resource_id]).storages(params[:node_id])
      respond_to do |format|
        format.json { render :json => storages }
      end
    end

    # GET foreman_fog_proxmox/isostorages/:compute_resource_id/:node_id
    def iso_storages_by_id_and_node
      storages = load_compute_resource(params[:compute_resource_id]).storages(params[:node_id], 'iso')
      respond_to do |format|
        format.json { render :json => storages }
      end
    end

    # GET foreman_fog_proxmox/bridges/:compute_resource_id/:node_id
    def bridges_by_id_and_node
      bridges = load_compute_resource(params[:compute_resource_id]).bridges(params[:node_id])
      respond_to do |format|
        format.json { render :json => bridges }
      end
    end

    # GET foreman_fog_proxmox/volumes/:compute_resource_id/:node_id/:storage
    def volumes_by_node_and_storage
      cr = ComputeResource.find(params[:compute_resource_id])
      node_id = params[:node_id]
      storage = params[:storage]

      vols = cr.storages(node_id).find { |s| s.storage == storage }&.volumes || []

      render json: Array(vols).map { |v|
        h = v.respond_to?(:as_json) ? v.as_json : v
        { volid: (h[:volid] || h['volid']), content: (h[:content] || h['content']) }
      }
    end

    # GET foreman_fog_proxmox/metadata/:compute_resource_id
    def metadata
      cr = ComputeResource.find(params[:compute_resource_id])
      nodes = Array(cr.nodes)

      render json: {
        nodes: extract_nodes(nodes),
        pools: extract_pools(cr),
        storages: extract_storages(cr, nodes),
        bridges: extract_bridges(cr, nodes),
        images: extract_images(cr),
      }
    end

    private

    def extract_nodes(nodes)
      nodes.map { |node| { node: node.node } }
    end

    def extract_pools(compute_resource)
      Array(compute_resource.pools).map do |p|
        poolid = p.respond_to?(:poolid) ? p.poolid : (p[:poolid] || p['poolid'])
        { poolid: poolid }
      end
    end

    def extract_storages(compute_resource, nodes)
      nodes.flat_map do |node|
        Array(compute_resource.storages(node.node)).map do |storage|
          {
            storage: storage.storage,
            node_id: node.node,
            content: storage.content,
            avail: storage.avail,
            used: storage.used,
            total: storage.total,
          }
        end
      end
    end

    def extract_bridges(compute_resource, nodes)
      nodes.flat_map do |node|
        Array(compute_resource.bridges(node.node)).map do |bridge|
          {
            node_id: node.node,
            iface: bridge.iface,
          }
        end
      end
    end

    def extract_images(compute_resource)
      images = compute_resource.images
      images = images.order(:name) if images.respond_to?(:order)

      Array(images).map do |image|
        data = image.respond_to?(:as_json) ? image.as_json : image
        uuid = image_value(image, data, :uuid, :id)

        {
          uuid: uuid,
          name: image_value(image, data, :name),
          disks: image_disks(compute_resource, uuid),
        }
      end
    end

    def image_disks(compute_resource, uuid)
      return nil unless uuid && compute_resource.respond_to?(:find_vm_by_uuid)

      compute_resource.find_vm_by_uuid(uuid)&.disks
    rescue ActiveRecord::RecordNotFound, StandardError
      nil
    end

    def image_value(image, data, *keys)
      keys.each do |key|
        value = [image.try(key), data.try(:[], key), data.try(:[], key.to_s)].find(&:present?)
        return value if value.present?
      end

      nil
    end

    def load_compute_resource(compute_resource_id)
      ComputeResource.find(compute_resource_id)
    end
  end
end
