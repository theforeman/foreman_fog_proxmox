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
  module Controller
      module HostsControllerExtensions
        extend ActiveSupport::Concern

        module Overrides
          def compute_resource_selected
            return not_found unless (params[:host] && (id=params[:host][:compute_resource_id]))
            Taxonomy.as_taxonomy @organization, @location do
              compute_profile_id = params[:host][:compute_profile_id] || Hostgroup.find_by_id(params[:host][:hostgroup_id]).try(:inherited_compute_profile_id)
              compute_resource = ComputeResource.authorized(:view_compute_resources).find_by_id(id)
              compute_resource_type = compute_resource.type
              vm_type = params[:host][:vm_type]
              unless (compute_resource_type != 'ForemanFogProxmox::Proxmox' || vm_type)
                render :partial => "foreman_fog_proxmox/vm_type/select_tab_content", :locals => { :compute_resource => compute_resource, :vm_type => nil }
              else
                render :partial => "compute", :locals => { :compute_resource => compute_resource,
                                                         :vm_attrs         => compute_resource.compute_profile_attributes_for(compute_profile_id) }
              end
            end
          rescue ActionView::Template::Error => exception
            process_ajax_error exception, 'render compute resource template'
          end
        end

        included do
          prepend Overrides
        end

      end
  end
end
