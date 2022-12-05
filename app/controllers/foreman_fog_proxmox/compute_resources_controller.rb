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

    private

    def load_compute_resource(compute_resource_id)
      ComputeResource.find(compute_resource_id)
    end
  end
end
