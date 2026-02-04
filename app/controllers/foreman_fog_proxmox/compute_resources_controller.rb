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

      render json: {
        nodes: extract_nodes(cr),
        pools: extract_pools(cr),
        storages: extract_storages(cr),
        bridges: extract_bridges(cr),
      }
    end

    private

    def extract_nodes(compute_resource)
      Array(compute_resource.nodes).map { |n| { node: n.node } }
    end

    def extract_pools(compute_resource)
      Array(compute_resource.pools).map do |p|
        poolid = p.respond_to?(:poolid) ? p.poolid : (p[:poolid] || p['poolid'])
        { poolid: poolid }
      end
    end

    def extract_storages(compute_resource)
      Array(compute_resource.storages).map do |s|
        h = s.respond_to?(:as_json) ? s.as_json : s
        {
          storage: (h[:storage] || h['storage']),
          node_id: (h[:node_id] || h['node_id']),
          content: (h[:content] || h['content']),
          avail: (h[:avail] || h['avail']),
          used: (h[:used] || h['used']),
          total: (h[:total] || h['total']),
        }
      end
    end

    def extract_bridges(compute_resource)
      Array(compute_resource.bridges).map do |b|
        h = b.respond_to?(:as_json) ? b.as_json : b
        {
          node_id: (h[:node_id] || h['node_id']),
          iface: (h[:iface] || h['iface']),
        }
      end
    end

    def load_compute_resource(compute_resource_id)
      ComputeResource.find(compute_resource_id)
    end
  end
end
