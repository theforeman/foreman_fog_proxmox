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

module Orchestration
  module Proxmox
    module Compute
      extend ActiveSupport::Concern

      def setComputeUpdate
        logger.info "Update Proxmox Compute instance for #{name}"
        final_compute_attributes = compute_attributes.merge(compute_resource.host_compute_attrs(self))
        compute_resource.save_vm uuid, final_compute_attributes
      rescue StandardError => e
        failure format(_('Failed to update a compute %{compute_resource} instance %{name}: %{e}'), :compute_resource => compute_resource, :name => name, :e => e), e
      end

      def delComputeUpdate
        logger.info "Undo Update Proxmox Compute instance for #{name}"
        final_compute_attributes = old.compute_attributes.merge(compute_resource.host_compute_attrs(old))
        compute_resource.save_vm uuid, final_compute_attributes
      rescue StandardError => e
        failure format(_('Failed to undo update compute %{compute_resource} instance %{name}: %{e}'), :compute_resource => compute_resource, :name => name, :e => e), e
      end
    end
  end
end
