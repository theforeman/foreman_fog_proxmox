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
      module ComputeResource
        extend ActiveSupport::Concern

        class_methods do
          def compute_resource_params_filter
            super.tap do |filter|
              filter.permit :ssl_verify_peer,
                            :ssl_certs, :node_id, :disable_proxy, :cr_id, :renew
            end
          end

          def compute_resource_params
            self.class.compute_resource_params_filter.filter_params(params, parameter_filter_context)
          end
        end
      end
    end
  end
end
