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

module ProxmoxComputeControllersHelper
  CONTROLLER_LIMITS = { 'ide' => 3, 'sata' => 5, 'scsi' => 30, 'virtio' => 15 }.freeze

  def proxmox_controllers_map
    proxmox_controllers_cloudinit_map << ForemanFogProxmox::OptionsSelect.new(name: 'VirtIO Block', id: 'virtio',
      range: CONTROLLER_LIMITS['virtio'])
  end

  def proxmox_controllers_cloudinit_map
    [ForemanFogProxmox::OptionsSelect.new(id: 'ide', name: 'IDE', range: CONTROLLER_LIMITS['ide']),
     ForemanFogProxmox::OptionsSelect.new(id: 'sata', name: 'SATA', range: CONTROLLER_LIMITS['sata']),
     ForemanFogProxmox::OptionsSelect.new(id: 'scsi', name: 'SCSI', range: CONTROLLER_LIMITS['scsi'])]
  end

  def proxmox_scsi_controllers_map
    [OpenStruct.new(id: 'lsi', name: 'LSI 53C895A (Default)'),
     OpenStruct.new(id: 'lsi53c810', name: 'LSI 53C810'),
     OpenStruct.new(id: 'virtio-scsi-pci', name: 'VirtIO SCSI'),
     OpenStruct.new(id: 'virtio-scsi-single', name: 'VirtIO SCSI Single'),
     OpenStruct.new(id: 'megasas', name: 'MegaRAID SAS 8708EM2'),
     OpenStruct.new(id: 'pvscsi', name: 'VMware PVSCSI')]
  end
end
