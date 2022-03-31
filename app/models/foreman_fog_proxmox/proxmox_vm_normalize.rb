# frozen_string_literal: true

# Copyright 2019 Tristan Robert

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

require 'fog/proxmox/helpers/disk_helper'

module ForemanFogProxmox
  module ProxmoxVmNormalize
    include ProxmoxVmHelper

    def complete_volume_with_default_attributes(volume_attributes, type)
      volume_attributes_completed = volume_attributes
      volume_attributes_completed = hard_disk_typed_defaults('lxc') if type == 'qemu' && Fog::Proxmox::DiskHelper.rootfs?(volume_attributes[:id])
      volume_attributes_completed = hard_disk_typed_defaults('qemu') if type == 'lxc' && Fog::Proxmox::DiskHelper.server_disk?(volume_attributes[:id])
      logger.debug(format(_('complete_volume_with_default_attributes(%<type>s): volume_attributes_completed=%<volume_attributes_completed>s'), type: type, volume_attributes_completed: volume_attributes_completed))
      volume_attributes_completed
    end

    def complete_with_default_attributes(new_attr, type)
      options = new_attr
      options = vm_typed_instance_defaults(type).merge(new_attr) unless new_attr.key?('vmid') && !ForemanFogProxmox::Value.empty?(new_attr['vmid'])
      options[:volumes_attributes] = Hash[options[:volumes_attributes].map { |key, volume_attributes| [key, complete_volume_with_default_attributes(volume_attributes, type)] }].deep_symbolize_keys
      logger.debug(format(_('complete_with_default_attributes(%<type>s): options=%<options>s'), type: type, options: options))
      options
    end
  end
end
