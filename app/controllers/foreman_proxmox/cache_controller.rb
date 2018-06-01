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
  class CacheController < ::ApplicationController
    before_filter :load_compute_resource

    # POST = foreman_proxmox/cache/refresh
    def refresh
      type = params[:type]

      unless cache_attribute_whitelist.include?(type)
        process_error(:error_msg => "Error refreshing cache. #{type} is not a white listed attribute")
      end

      unless @compute_resource.respond_to?("#{type}!")
        process_error(:error_msg => "Error refreshing cache. Method '#{type}!' not found for compute resource" +
            @compute_resource.name)
      end

      respond_to do |format|
        format.json { render :json => @compute_resource.public_send("#{type}!") }
      end
    end

    private

    # List of methods to permit
    def cache_attribute_whitelist
      %w[networks hypervisors templates custom_templates builtin_templates storage_pools]
    end

    def load_compute_resource
      @compute_resource = ComputeResource.find_by(id: params['compute_resource_id'])
    end
  end
end
