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

require 'foreman_fog_proxmox/value'

module ForemanFogProxmox
  module HashCollection
    def self.add_and_format_element(dest, dest_key, origin, origin_key, format = :to_s)
      dest[dest_key] = origin[origin_key].send(format) if origin[origin_key]
    end

    def self.remove_empty_values(h)
      h.delete_if { |_key, value| ForemanFogProxmox::Value.empty?(value) }
    end
    
    def self.remove_keys(h, excluded_keys)
      h.delete_if { |key, _value| excluded_keys.include?(key) }
    end
    
    def self.new_hash_reject_keys(h, excluded_keys)
      h.reject { |key, _value| excluded_keys.include?(key) }
    end
  end
end
