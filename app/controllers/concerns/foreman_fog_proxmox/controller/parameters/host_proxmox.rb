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
    module Parameters
      module HostProxmox
        extend ActiveSupport::Concern

        class_methods do
          def host_params_filter
            super.tap do |filter|   
              filter.permit :vm_type
            end
          end

          def host_params(top_level_hash = controller_name.singularize)
            keep_param(params, top_level_hash, :compute_attributes) do
              self.class.host_params_filter.filter_params(params, parameter_filter_context, top_level_hash)
            end.tap do |normalized|
              if parameter_filter_context.ui? && normalized["compute_attributes"] && normalized["compute_attributes"]["scsi_controllers"]
                normalize_scsi_attributes(normalized["compute_attributes"])
              end
            end
          end
        end
      end
    end
  end
end
