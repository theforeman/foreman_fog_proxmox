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
    [['ide', 'IDE', 3], ['sata', 'SATA', 5], ['scsi', 'SCSI', 13], ['VirtIO Block', 'virtio', 15]]
  end

  def proxmox_devices_map(bus)
    array_up_to(bus[2])
  end

  def array_up_to(i)
    (0..i - 1).to_a
  end

  def proxmox_caches_map
    [['directsync', 'Direct sync'],
     ['writethrough', 'Write through'],
     ['writeback', 'Write back'],
     ['unsafe', 'Write back unsafe'],
     ['none', 'No cache']]
  end

  def proxmox_cpus_map
    [%w[486 486],
     %w[athlon athlon],
     %w[core2duo core2duo],
     %w[coreduo coreduo],
     %w[kvm32 kvm32],
     %w[kvm64 kvm64],
     %w[pentium pentium],
     %w[pentium2 pentium2],
     %w[pentium3 pentium3],
     %w[phenom phenom],
     %w[qemu32 qemu32],
     %w[qemu64 qemu64],
     %w[Conroe Conroe],
     %w[Penryn Penryn],
     %w[Nehalem Nehalem],
     %w[Westmere Westmere],
     %w[SandyBridge SandyBridge],
     %w[IvyBridge IvyBridge],
     %w[Haswell Haswell],
     ['Haswell-noTSX', 'Haswell-noTSX'],
     %w[Broadwell Broadwell],
     ['Broadwell-noTSX', 'Broadwell-noTSX'],
     ['Skylake-Client', 'Skylake-Client'],
     %w[Opteron_G1 Opteron_G1],
     %w[Opteron_G2 Opteron_G2],
     %w[Opteron_G3 Opteron_G3],
     %w[Opteron_G4 Opteron_G4],
     %w[Opteron_G5 Opteron_G5],
     %w[host host]]
  end

  def proxmox_scsihw_map
    [%w[lsi lsi],
     %w[lsi53c810 lsi53c810],
     %w[megasas megasas],
     ['virtio-scsi-pci', 'virtio-scsi-pci'],
     ['virtio-scsi-single', 'virtio-scsi-single'],
     %w[pvscsi pvscsi]]
  end

  def proxmox_networkcards_map
    [['e1000', 'Intel E1000'],
     ['virtio', 'VirtIO (paravirtualized)'],
     ['rtl8139', 'Realtek RTL8139'],
     ['vmxnet3', 'VMware vmxnet3']]
  end
end
