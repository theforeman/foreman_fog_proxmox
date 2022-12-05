# frozen_string_literal: true

# Copyright 2021 Tristan Robert

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

module HostExt
  module Proxmox
    module Associator
      extend ActiveSupport::Concern
      included do
        prepend Overrides
      end
      module Overrides
        def associate!(cr, vm)
          self.uuid = proxmox_vm_id(cr, vm)
          self.compute_resource_id = cr.id
          save!(:validate => false) # don't want to trigger callbacks
        end

        def proxmox_vm_id(compute_resource, vm)
          id = vm.identity
          id = vm.unique_cluster_identity(compute_resource) if compute_resource.instance_of?(ForemanFogProxmox::Proxmox)
          id
        end
      end

      def for_vm_uuid(cr, vm)
        where(:compute_resource_id => cr.id,
          :uuid => Array.wrap(vm).compact.map(cr.id.to_s + '_' + vm&.identity).map(&:to_s))
      end
    end
  end
end
