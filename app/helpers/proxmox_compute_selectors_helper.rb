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

require 'fog_extensions/proxmox/key_pair'

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
    [FogExtensions::Proxmox::KeyPair.new(id: '486', name: '486'),
     FogExtensions::Proxmox::KeyPair.new(id: 'athlon', name: 'athlon'),
     FogExtensions::Proxmox::KeyPair.new(id: 'core2duo', name: 'core2duo'),
     FogExtensions::Proxmox::KeyPair.new(id: 'coreduo', name: 'coreduo'),
     FogExtensions::Proxmox::KeyPair.new(id: 'kvm32', name: 'kvm32'),
     FogExtensions::Proxmox::KeyPair.new(id: 'kvm64', name: '(Default) kvm64'),
     FogExtensions::Proxmox::KeyPair.new(id: 'pentium', name: 'pentium'),
     FogExtensions::Proxmox::KeyPair.new(id: 'pentium2', name: 'pentium2'),
     FogExtensions::Proxmox::KeyPair.new(id: 'pentium3', name: 'pentium3'),
     FogExtensions::Proxmox::KeyPair.new(id: 'phenom', name: 'phenom'),
     FogExtensions::Proxmox::KeyPair.new(id: 'qemu32', name: 'qemu32'),
     FogExtensions::Proxmox::KeyPair.new(id: 'qemu64', name: 'qemu64'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Conroe', name: 'Conroe'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Penryn', name: 'Penryn'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Nehalem', name: 'Nehalem'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Westmere', name: 'Westmere'),
     FogExtensions::Proxmox::KeyPair.new(id: 'SandyBridge', name: 'SandyBridge'),
     FogExtensions::Proxmox::KeyPair.new(id: 'IvyBridge', name: 'IvyBridge'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Haswell', name: 'Haswell'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Haswell-noTSX', name: 'Haswell-noTSX'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Broadwell', name: 'Broadwell'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Broadwell-noTSX', name: 'Broadwell-noTSX'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Skylake-Client', name: 'Skylake-Client'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Opteron_G1', name: 'Opteron_G1'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Opteron_G2', name: 'Opteron_G2'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Opteron_G3', name: 'Opteron_G3'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Opteron_G4', name: 'Opteron_G4'),
     FogExtensions::Proxmox::KeyPair.new(id: 'Opteron_G5', name: 'Opteron_G5'),
     FogExtensions::Proxmox::KeyPair.new(id: 'host', name: 'host')]
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
