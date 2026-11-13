# frozen_string_literal: true

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

module ProxmoxVMConfigAttrsHelper
  include ProxmoxVMConfigHelper

  def agent_attrs(param_scope, config)
    settings = Fog::Proxmox::AgentHelper.extract(config.agent)
    freeze_fs = settings['freeze-fs-on-backup']
    values = {
      'agent' => bool_to_proxmox_flag(settings['enabled']),
      'agent_freeze_fs' => bool_to_proxmox_flag(freeze_fs),
      'agent_fstrim_cloned_disks' => bool_to_proxmox_flag(settings['fstrim_cloned_disks']),
      'agent_type' => settings['type'],
    }
    values.each_with_object({}) do |(key, value), attrs|
      attrs.merge!(config_field_attrs(param_scope, key, value))
    end
  end

  def hotplug_attrs(param_scope, config)
    settings = Fog::Proxmox::HotplugHelper.extract(config.hotplug)
    hotplug_enabled = settings[:enabled]
    enabled_devices = settings[:devices]

    attrs = {
      'hotplug' => {
        name: "#{param_scope}[config_attributes][hotplug]",
        value: hotplug_enabled ? '1' : '0',
      },
    }

    HOTPLUG_DEVICES.each do |device|
      key = "hotplug_#{device}"
      value = enabled_devices.include?(device) ? '1' : '0'
      attrs.merge!(config_field_attrs(param_scope, key, value))
    end

    attrs
  end

  def cpu_flags_attrs(param_scope, config)
    flag_attrs = ActiveSupport::HashWithIndifferentAccess.new
    Fog::Proxmox::CpuHelper.flags.each_key do |key|
      flag_attrs[key] = config_field_attrs(param_scope, key.to_s, config.public_send(key)).values.first
    end
    flag_attrs
  end

  def config_field_attrs(param_scope, key, value)
    {
      snake_to_camel(key) => {
        name: "#{param_scope}[config_attributes][#{key}]", value: value
      },
    }
  end
end
