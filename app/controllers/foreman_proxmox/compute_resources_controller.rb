# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanProxmox.

# ForemanProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanProxmox. If not, see <http://www.gnu.org/licenses/>.

module ForemanProxmox
  class ComputeResourcesController < ::ApplicationController
    before_action :load_compute_resource

    # GET foreman_proxmox/isos/:storage
    def isos
      volumes = @compute_resource.isos(params[:storage])
      respond_to do |format|
        format.json { render :json => volumes }
      end
    end

    private

    def load_compute_resource
      @compute_resource = ComputeResource.find_by(type: 'ForemanProxmox::Proxmox')
    end
  end
end
