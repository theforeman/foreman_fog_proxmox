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

module HostExt
  module Proxmox
    module Interfaces
      extend ActiveSupport::Concern
      def update(attributes = {})
        add_interfaces_to_compute_attributes(attributes) if provider == 'Proxmox' && !attributes.nil? && attributes.key?('compute_attributes')
        super(attributes)
      end

      def add_interfaces_to_compute_attributes(attributes)
        attributes['compute_attributes'].store('interfaces_attributes', {})
        attributes['interfaces_attributes'].each do |index, interface_attributes|
          add_interface_to_compute_attributes(index, interface_attributes, attributes['compute_attributes']['interfaces_attributes'])
        end
      end

      def add_interface_to_compute_attributes(index, interface_attributes, compute_attributes)
        compute_attributes[index] = {}
        compute_attributes[index].store('id', interface_attributes['identifier'])
        compute_attributes[index].store('_delete', interface_attributes['_destroy'])
        compute_attributes[index].store('macaddr', interface_attributes['mac'])
        compute_attributes[index].merge!(interface_attributes['compute_attributes'].reject { |k, _v| k == 'id' })
      end
    end
  end
end
