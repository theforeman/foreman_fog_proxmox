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

module ForemanFogProxmox
  module ComputeResourceHostAssociator
    extend ActiveSupport::Concern
    included do
      prepend Overrides
    end
    module Overrides
      def associate_hosts
        compute_resource.vms(:eager_loading => true).each do |vm|
          associate_vm(vm) if Host.for_vm_uuid(compute_resource, vm).empty?
        end
      end
    end
  end
end
