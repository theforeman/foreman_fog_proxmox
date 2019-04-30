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

module FogExtensions
    module Proxmox
        module Node
            extend ActiveSupport::Concern
            def all(options = {})
                vms = servers.all 
                vms += containers.all
                vms
            end
            def each(collection_filters = {})
                if block_given?
                Kernel.loop do
                    break unless collection_filters[:marker]
                    page = all(collection_filters)
                    # We need to explicitly use the base 'each' method here on the page,
                    #  otherwise we get infinite recursion
                    base_each = Fog::Collection.instance_method(:each)
                    base_each.bind(page).call { |item| yield item }
                end
                end
                self
            end
        end
    end
end  