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

require 'fog/proxmox/helpers/ip_helper'

module FogExtensions
  module Proxmox
    module Interface
      extend ActiveSupport::Concern
      def mac
        macaddr
      end

      def dhcp
        ip == 'dhcp'
      end

      def dhcp6
        ip6 == 'dhcp'
      end

      def dhcp=(value)
        @dhcp = value
      end

      def dhcp6=(value)
        @dhcp6 = value
      end

      def cidr
        Fog::Proxmox::IpHelper.prefix(ip) if ip
      end

      def cidr6
        Fog::Proxmox::IpHelper.prefix6(ip6) if ip6
      end
    end
  end
end
