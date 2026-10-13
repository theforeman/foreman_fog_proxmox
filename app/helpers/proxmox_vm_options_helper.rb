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

require 'fog/proxmox/helpers/agent_helper'
require 'fog/proxmox/helpers/hotplug_helper'

module ProxmoxVMOptionsHelper
  HOTPLUG_DEVICES = Fog::Proxmox::HotplugHelper::DEVICES
  AGENT_FIELDS = %w[agent_freeze_fs agent_fstrim_cloned_disks agent_type].freeze

  def parse_agent(config)
    config = config.with_indifferent_access
    return config unless AGENT_FIELDS.any? { |key| config.key?(key) }

    agent_enabled = bool_to_proxmox_flag(config['agent'])
    freeze_fs = bool_to_proxmox_flag(config.delete('agent_freeze_fs'))
    fstrim = bool_to_proxmox_flag(config.delete('agent_fstrim_cloned_disks'))
    agent_type = config.delete('agent_type').presence || 'virtio'
    config['agent'] = Fog::Proxmox::AgentHelper.flatten(
      'enabled' => agent_enabled, 'freeze-fs-on-backup' => freeze_fs,
      'fstrim_cloned_disks' => fstrim, 'type' => agent_type
    )
    config
  end

  # We can move this later to a general helper file so it can be used by other methods
  def bool_to_proxmox_flag(value)
    Foreman::Cast.to_bool(value) ? '1' : '0'
  end

  def parse_hotplug(config)
    config = config.with_indifferent_access
    return config unless HOTPLUG_DEVICES.any? { |device| config.key?("hotplug_#{device}") }

    hotplug_enabled = Foreman::Cast.to_bool(config['hotplug'])

    hotplug_devices_enabled = HOTPLUG_DEVICES.select do |device|
      Foreman::Cast.to_bool(config.delete("hotplug_#{device}"))
    end

    config['hotplug'] = Fog::Proxmox::HotplugHelper.flatten(
      enabled: hotplug_enabled, devices: hotplug_enabled ? hotplug_devices_enabled : []
    )
    config
  end
end
