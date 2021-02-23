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
      dest[dest_key] = origin[origin_key].send(format) if origin && origin[origin_key]
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

    def self.new_hash_reject_empty_values(h)
      h.reject { |_key, value| ForemanFogProxmox::Value.empty?(value) }
    end

    def self.new_hash_transform_values(h, transformation)
      h.transform_values { |value| value.send(transformation) }
    end

    def self.equals?(h1, h2)
      new_h1 = new_hash_transform_values(h1, :to_s)
      new_sorted_h1 = new_h1.sort_by { |key, _value| key }.to_h
      new_h2 = new_hash_transform_values(h2, :to_s)
      new_sorted_h2 = new_h2.sort_by { |key, _value| key }.to_h
      new_sorted_h1.keys == new_sorted_h2.keys && new_sorted_h1.values == new_sorted_h2.values
    end

    def self.stringify_keys(old_h)
      h = old_h.map do |k, v|
        v_str = if v.instance_of? Hash
                  v.stringify_keys
                else
                  v
                end

        [k.to_s, v_str]
      end
      Hash[h]
    end
  end
end
