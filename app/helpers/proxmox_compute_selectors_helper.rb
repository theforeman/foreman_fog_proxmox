# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanProxmox.

# ForemanProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanProxmox. If not, see <http://www.gnu.org/licenses/>.

module ProxmoxComputeSelectorsHelper
  def proxmox_buses_map
    [ForemanProxmox::OptionsSelect.new(id:'ide', name: 'IDE', range: 3), 
      ForemanProxmox::OptionsSelect.new(id:'sata', name: 'SATA', range: 5), 
        ForemanProxmox::OptionsSelect.new(id:'scsi', name: 'SCSI', range: 13), 
          ForemanProxmox::OptionsSelect.new(name:'VirtIO Block', id: 'virtio', range: 15)]
  end

  def bus(id)
    proxmox_buses_map.find { |bus| bus.id == id}
  end

  def proxmox_devices_map(bus_id)
    devices = []
    bus_range = bus(bus_id) ? bus(bus_id).range  : 1
    array_up_to(bus_range).each { |i| devices << ForemanProxmox::OptionsSelect.new(id: i, name: i) }
    devices
  end

  def array_up_to(i)
    (0..i - 1).to_a
  end

  def proxmox_caches_map
    [ForemanProxmox::OptionsSelect.new(id: 'directsync', name: 'Direct sync'),
     ForemanProxmox::OptionsSelect.new(id: 'writethrough', name: 'Write through'),
     ForemanProxmox::OptionsSelect.new(id: 'writeback', name: 'Write back'),
     ForemanProxmox::OptionsSelect.new(id: 'unsafe', name: 'Write back unsafe'),
     ForemanProxmox::OptionsSelect.new(id: 'none', name: 'No cache')]
  end

  def proxmox_cpus_map
    [ForemanProxmox::OptionsSelect.new(id: '486', name: '486'),
     ForemanProxmox::OptionsSelect.new(id: 'athlon', name: 'athlon'),
     ForemanProxmox::OptionsSelect.new(id: 'core2duo', name: 'core2duo'),
     ForemanProxmox::OptionsSelect.new(id: 'coreduo', name: 'coreduo'),
     ForemanProxmox::OptionsSelect.new(id: 'kvm32', name: 'kvm32'),
     ForemanProxmox::OptionsSelect.new(id: 'kvm64', name: '(Default) kvm64'),
     ForemanProxmox::OptionsSelect.new(id: 'pentium', name: 'pentium'),
     ForemanProxmox::OptionsSelect.new(id: 'pentium2', name: 'pentium2'),
     ForemanProxmox::OptionsSelect.new(id: 'pentium3', name: 'pentium3'),
     ForemanProxmox::OptionsSelect.new(id: 'phenom', name: 'phenom'),
     ForemanProxmox::OptionsSelect.new(id: 'qemu32', name: 'qemu32'),
     ForemanProxmox::OptionsSelect.new(id: 'qemu64', name: 'qemu64'),
     ForemanProxmox::OptionsSelect.new(id: 'Conroe', name: 'Conroe'),
     ForemanProxmox::OptionsSelect.new(id: 'Penryn', name: 'Penryn'),
     ForemanProxmox::OptionsSelect.new(id: 'Nehalem', name: 'Nehalem'),
     ForemanProxmox::OptionsSelect.new(id: 'Westmere', name: 'Westmere'),
     ForemanProxmox::OptionsSelect.new(id: 'SandyBridge', name: 'SandyBridge'),
     ForemanProxmox::OptionsSelect.new(id: 'IvyBridge', name: 'IvyBridge'),
     ForemanProxmox::OptionsSelect.new(id: 'Haswell', name: 'Haswell'),
     ForemanProxmox::OptionsSelect.new(id: 'Haswell-noTSX', name: 'Haswell-noTSX'),
     ForemanProxmox::OptionsSelect.new(id: 'Broadwell', name: 'Broadwell'),
     ForemanProxmox::OptionsSelect.new(id: 'Broadwell-noTSX', name: 'Broadwell-noTSX'),
     ForemanProxmox::OptionsSelect.new(id: 'Skylake-Client', name: 'Skylake-Client'),
     ForemanProxmox::OptionsSelect.new(id: 'Opteron_G1', name: 'Opteron_G1'),
     ForemanProxmox::OptionsSelect.new(id: 'Opteron_G2', name: 'Opteron_G2'),
     ForemanProxmox::OptionsSelect.new(id: 'Opteron_G3', name: 'Opteron_G3'),
     ForemanProxmox::OptionsSelect.new(id: 'Opteron_G4', name: 'Opteron_G4'),
     ForemanProxmox::OptionsSelect.new(id: 'Opteron_G5', name: 'Opteron_G5'),
     ForemanProxmox::OptionsSelect.new(id: 'host', name: 'host')]
  end

  def proxmox_scsihw_map
    [ForemanProxmox::OptionsSelect.new(id: 'lsi', name: 'lsi'),
     ForemanProxmox::OptionsSelect.new(id: 'lsi53c810', name: 'lsi53c810'),
     ForemanProxmox::OptionsSelect.new(id: 'megasas', name: 'megasas'),
     ForemanProxmox::OptionsSelect.new(id: 'virtio-scsi-pci', name: 'virtio-scsi-pci'),
      ForemanProxmox::OptionsSelect.new(id: 'virtio-scsi-single', name: 'virtio-scsi-single'),
     ForemanProxmox::OptionsSelect.new(id: 'pvscsi', name: 'pvscsi')]
  end

  def proxmox_networkcards_map
    [ForemanProxmox::OptionsSelect.new(id: 'e1000', name:  'Intel E1000'),
      ForemanProxmox::OptionsSelect.new(id: 'virtio', name:  'VirtIO (paravirtualized)'),
      ForemanProxmox::OptionsSelect.new(id: 'rtl8139', name:  'Realtek RTL8139'),
        ForemanProxmox::OptionsSelect.new(id: 'vmxnet3', name:  'VMware vmxnet3')]
  end
end
