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

module ProxmoxVMHelper
  include ProxmoxVMInterfacesHelper
  include ProxmoxVMVolumesHelper
  include ProxmoxVMConfigHelper
  include ProxmoxVMOsTemplateHelper

  def vm_collection(type)
    collection = :servers
    collection = :containers if type == 'lxc'
    collection
  end

  # Convert a foreman form server/container vm hash into a fog-proxmox server/container attributes hash
  def parse_typed_vm(args, type)
    args = ActiveSupport::HashWithIndifferentAccess.new(args)
    return {} unless args
    return {} if args.empty?
    return {} unless args['type'] == type

    logger.debug("parse_typed_vm(#{type}): args=#{args}")
    parsed_vm = parsed_typed_config(args, type)
    parsed_vm = parsed_typed_interfaces(args, type, parsed_vm)
    parsed_vm = parsed_typed_volumes(args, type, parsed_vm)
    logger.debug("parse_typed_vm(#{type}): parsed_vm=#{parsed_vm}")
    parsed_vm
  end
end
