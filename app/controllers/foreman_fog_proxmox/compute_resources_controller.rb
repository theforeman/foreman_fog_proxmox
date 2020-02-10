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
    before_action :load_compute_resource

    # GET foreman_fog_proxmox/isos/:node_id/:storage
    def isos_by_node_and_storage
      volumes = @compute_resource.images_by_storage(params[:node_id], params[:storage], 'iso')
      respond_to do |format|
        format.json { render :json => volumes }
      end
    end

    # GET foreman_fog_proxmox/ostemplates/:node_id/:storage
    def ostemplates_by_node_and_storage
      volumes = @compute_resource.images_by_storage(params[:node_id], params[:storage], 'vztmpl')
      respond_to do |format|
        format.json { render :json => volumes }
      end
    end

    # GET foreman_fog_proxmox/isos/:node_id
    def isos_by_node
      volumes = @compute_resource.images_by_storage(params[:node_id], params[:storage], 'iso')
      respond_to do |format|
        format.json { render :json => volumes }
      end
    end

    # GET foreman_fog_proxmox/ostemplates/:node_id
    def ostemplates_by_node
      storages = @compute_resource.storages(params[:node_id], 'vztmpl')
      respond_to do |format|
        format.json { render :json => storages }
      end
    end

    # GET foreman_fog_proxmox/storages/:node_id
    def storages_by_node
      storages = @compute_resource.storages(params[:node_id])
      respond_to do |format|
        format.json { render :json => storages }
      end
    end

    # GET foreman_fog_proxmox/isostorages/:node_id
    def iso_storages_by_node
      storages = @compute_resource.storages(params[:node_id], 'iso')
      respond_to do |format|
        format.json { render :json => storages }
      end
    end

    # GET foreman_fog_proxmox/bridges/:node_id
    def bridges_by_node
      bridges = @compute_resource.bridges(params[:node_id])
      respond_to do |format|
        format.json { render :json => bridges }
      end
    end

    private

    def load_compute_resource
      @compute_resource = ComputeResource.find_by(type: 'ForemanFogProxmox::Proxmox')
    end
  end
end
