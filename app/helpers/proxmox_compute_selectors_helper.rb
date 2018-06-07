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
    [FogExtensions::Proxmox::KeyPair.new(id:'ide', name: 'IDE', range: 3), 
      FogExtensions::Proxmox::KeyPair.new(id:'sata', name: 'SATA', range: 5), 
        FogExtensions::Proxmox::KeyPair.new(id:'scsi', name: 'SCSI', range: 13), 
          FogExtensions::Proxmox::KeyPair.new(name:'VirtIO Block', id: 'virtio', range: 15)]
  end

  def proxmox_devices_map(bus)
    array_up_to(bus[:range])
  end

  def array_up_to(i)
    (0..i - 1).to_a
  end

  def proxmox_caches_map
    [FogExtensions::Proxmox::KeyPair.new(id: 'directsync', name: 'Direct sync'),
     FogExtensions::Proxmox::KeyPair.new(id: 'writethrough', name: 'Write through'),
     FogExtensions::Proxmox::KeyPair.new(id: 'writeback', name: 'Write back'),
     FogExtensions::Proxmox::KeyPair.new(id: 'unsafe', name: 'Write back unsafe'),
     FogExtensions::Proxmox::KeyPair.new(id: 'none', name: 'No cache')]
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
    [FogExtensions::Proxmox::KeyPair.new(id: 'lsi', name: 'lsi'),
     FogExtensions::Proxmox::KeyPair.new(id: 'lsi53c810', name: 'lsi53c810'),
     FogExtensions::Proxmox::KeyPair.new(id: 'megasas', name: 'megasas'),
     FogExtensions::Proxmox::KeyPair.new(id: 'virtio-scsi-pci', name: 'virtio-scsi-pci'),
      FogExtensions::Proxmox::KeyPair.new(id: 'virtio-scsi-single', name: 'virtio-scsi-single'),
     FogExtensions::Proxmox::KeyPair.new(id: 'pvscsi', name: 'pvscsi')]
  end

  def proxmox_networkcards_map
    [FogExtensions::Proxmox::KeyPair.new(id: 'e1000', name:  'Intel E1000'),
      FogExtensions::Proxmox::KeyPair.new(id: 'virtio', name:  'VirtIO (paravirtualized)'),
      FogExtensions::Proxmox::KeyPair.new(id: 'rtl8139', name:  'Realtek RTL8139'),
        FogExtensions::Proxmox::KeyPair.new(id: 'vmxnet3', name:  'VMware vmxnet3')]
  end
end
