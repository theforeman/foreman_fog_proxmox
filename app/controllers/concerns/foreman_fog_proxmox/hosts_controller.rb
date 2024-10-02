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
  module HostsController
    extend ActiveSupport::Concern
    included do
      prepend Overrides
    end
    module Overrides
      include ForemanFogProxmox::ProxmoxVMNew
      # Clone the host
      def clone
        super
        return true unless @host.compute_resource.instance_of?(ForemanFogProxmox::Proxmox)

        @host.compute_attributes[:vmid] = next_vmid
        @host.compute_attributes[:interfaces_attributes].each do |index, interface_attributes|
          @host.compute_attributes[:interfaces_attributes][index] =
            interface_attributes.merge(macaddr: nil).merge(hwaddr: nil).merge(ip: nil).merge(ip6: nil)
        end
        @host.compute_attributes[:volumes_attributes].each do |index, volume_attributes|
          @host.compute_attributes[:volumes_attributes][index] = volume_attributes.merge(volid: nil)
        end
      end

      private

      def bridges
        @host.compute_resource.bridges
      end

      def nodes
        @host.compute_resource.nodes
      end

      def storages
        @host.compute_resource.storages
      end
    end
  end
end
