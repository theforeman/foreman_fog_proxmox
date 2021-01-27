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

require 'fog/proxmox/helpers/disk_helper'
require 'fog/proxmox/helpers/nic_helper'
require 'foreman_fog_proxmox/value'
require 'foreman_fog_proxmox/hash_collection'

module ProxmoxVmOsTemplateHelper
  def ostemplate_keys
    ['ostemplate_storage', 'ostemplate_file']
  end

  def parse_ostemplate_without_keys(args)
    parse_container_ostemplate(args.select { |key, _value| ostemplate_keys.include? key })
  end

  def parse_ostemplate(args, config)
    ostemplate = parse_ostemplate_without_keys(args)
    ostemplate = parse_ostemplate_without_keys(config) unless ostemplate[:ostemplate]
    ostemplate
  end

  def parse_container_ostemplate(args)
    ostemplate = args['ostemplate']
    ostemplate_file = args['ostemplate_file']
    ostemplate ||= ostemplate_file
    parsed_ostemplate = { ostemplate: ostemplate }
    parsed_ostemplate
  end
end
