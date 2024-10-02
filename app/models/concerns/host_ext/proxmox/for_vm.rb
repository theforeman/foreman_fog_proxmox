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
    module ForVM
      extend ActiveSupport::Concern
      module ClassMethods
        def for_vm_uuid(cr, vm)
          uuid = vm&.identity
          uuid = cr.id.to_s + '_' + vm&.identity.to_s if cr.instance_of?(ForemanFogProxmox::Proxmox)
          where(:compute_resource_id => cr.id, :uuid => uuid)
        end
      end
    end
  end
end
