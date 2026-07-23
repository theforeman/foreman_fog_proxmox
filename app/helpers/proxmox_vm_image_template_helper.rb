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

require 'fog/proxmox/helpers/disk_helper'

module ProxmoxVMImageTemplateHelper
  def validate_image_template_disk_slots!(image, args)
    reserved_slots = image.config.disks.select(&:hard_disk?).map(&:id)
    limits = ProxmoxComputeControllersHelper::CONTROLLER_LIMITS
    volumes = args['volumes_attributes']&.values || []
    used_slots = reserved_slots + volumes.filter_map { |volume| hard_disk_slot(volume) }

    volumes.each do |volume_attributes|
      volume = volume_attributes.with_indifferent_access
      slot = hard_disk_slot(volume_attributes)
      next unless slot

      controller = volume[:controller]
      if reserved_slots.include?(slot)
        device = (0..limits.fetch(controller, -1)).find do |number|
          !used_slots.include?("#{controller}#{number}")
        end
        unless device
          raise ::Foreman::Exception,
            format(_('No free disk device is available for the %<controller>s controller.'), controller: controller)
        end

        volume_attributes['device'] = device.to_s
        volume_attributes['id'] = slot = "#{controller}#{device}"
      end
      used_slots << slot
    end
  end

  def hard_disk_slot(attributes)
    volume = attributes.with_indifferent_access
    id = volume[:id]
    id if volume_type?(volume, 'hard_disk') &&
          Fog::Proxmox::DiskHelper.server_disk?(id)
  end
end
