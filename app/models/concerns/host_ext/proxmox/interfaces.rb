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

module HostExt
  module Proxmox
    module Interfaces
      extend ActiveSupport::Concern
      def update(attributes = {})
        if provider == 'Proxmox' && !attributes.nil? && attributes.key?('compute_attributes')
          add_interfaces_to_compute_attributes(attributes)
        end
        super(attributes)
      end

      def add_interfaces_to_compute_attributes(attributes)
        attributes['compute_attributes'].store('interfaces_attributes', {})
        attributes['interfaces_attributes'].each do |index, interface_attributes|
          add_interface_to_compute_attributes(index, interface_attributes,
            attributes['compute_attributes']['interfaces_attributes'])
        end
      end

      def cidr_ip(interface_attributes, v = 4)
        key_ip = 'ip'
        key_ip += '6' if v == 6
        key_cidr = 'cidr'
        key_cidr += '6' if v == 6
        Fog::Proxmox::IpHelper.to_cidr(interface_attributes[key_ip],
          interface_attributes['compute_attributes'][key_cidr])
      end

      def add_interface_to_compute_attributes(index, interface_attributes, compute_attributes)
        compute_attributes[index] = {}
        compute_attributes[index].store('_delete', interface_attributes['_destroy'])
        compute_attributes[index].store('macaddr', interface_attributes['mac'])
        compute_attributes[index].store('ip', cidr_ip(interface_attributes))
        compute_attributes[index].store('ip6', cidr_ip(interface_attributes, 6))
        compute_attributes[index].merge(interface_attributes['compute_attributes'])
      end
    end
  end
end
