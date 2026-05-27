# frozen_string_literal: true

# Copyright 2026

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

module ForemanFogProxmox
  module ComputeAttributesUpdateDetector
    def update_required?(old_attrs, new_attrs)
      old_attrs = old_attrs.deep_symbolize_keys
      new_attrs = new_attrs.deep_symbolize_keys
      new_attrs.each do |key, new_v|
        old_v = old_attrs[key]
        if new_v.is_a?(Hash)
          unless old_v.is_a?(Hash)
            logger.debug "Scheduling compute instance update because #{key} changed it's value from '#{old_v}' (#{old_v.class}) to '#{new_v}' (#{new_v.class})"
            return true
          end
          return true if update_required?(old_v, new_v)
        elsif old_v.to_s != new_v.to_s
          logger.debug "Scheduling compute instance update because #{key} changed it's value from '#{old_v}' (#{old_v.class}) to '#{new_v}' (#{new_v.class})"
          return true
        end
      end
      false
    end
  end
end
