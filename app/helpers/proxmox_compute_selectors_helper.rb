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

module ProxmoxComputeSelectorsHelper
  def proxmox_types_map
    [OpenStruct.new(id: 'qemu', name: 'KVM/Qemu server'),
     OpenStruct.new(id: 'lxc', name: 'LXC container')]
  end

  def proxmox_archs_map
    [OpenStruct.new(id: 'amd64', name: '64 bits'),
     OpenStruct.new(id: 'i386', name: '32 bits')]
  end

  def proxmox_ostypes_map
    [OpenStruct.new(id: 'debian', name: 'Debian'),
     OpenStruct.new(id: 'ubuntu', name: 'Ubuntu'),
     OpenStruct.new(id: 'centos', name: 'CentOS'),
     OpenStruct.new(id: 'fedora', name: 'Fedora'),
     OpenStruct.new(id: 'opensuse', name: 'OpenSuse'),
     OpenStruct.new(id: 'archlinux', name: 'ArchLinux'),
     OpenStruct.new(id: 'gentoo', name: 'Gentoo'),
     OpenStruct.new(id: 'alpine', name: 'Alpine'),
     OpenStruct.new(id: 'unmanaged', name: 'Unmanaged')]
  end

  def proxmox_operating_systems_map
    [OpenStruct.new(id: 'other', name: 'Unspecified OS'),
     OpenStruct.new(id: 'wxp', name: 'Microsoft Windows XP'),
     OpenStruct.new(id: 'w2k', name: 'Microsoft Windows 2000'),
     OpenStruct.new(id: 'w2k3', name: 'Microsoft Windows 2003'),
     OpenStruct.new(id: 'w2k8', name: 'Microsoft Windows 2008'),
     OpenStruct.new(id: 'wvista', name: 'Microsoft Windows Vista'),
     OpenStruct.new(id: 'win7', name: 'Microsoft Windows 7'),
     OpenStruct.new(id: 'win8', name: 'Microsoft Windows 8/2012/2012r2'),
     OpenStruct.new(id: 'win10', name: 'Microsoft Windows 10/2016'),
     OpenStruct.new(id: 'l24', name: 'Linux 2.4 Kernel'),
     OpenStruct.new(id: 'l26', name: 'Linux 2.6/3.X + Kernel'),
     OpenStruct.new(id: 'solaris', name: 'Solaris/OpenSolaris/OpenIndiania kernel')]
  end

  def proxmox_vgas_map
    [OpenStruct.new(id: 'std', name: 'Standard VGA'),
     OpenStruct.new(id: 'vmware', name: 'Vmware compatible'),
     OpenStruct.new(id: 'qxl', name: 'SPICE'),
     OpenStruct.new(id: 'qxl2', name: 'SPICE 2 monnitors'),
     OpenStruct.new(id: 'qxl3', name: 'SPICE 3 monnitors'),
     OpenStruct.new(id: 'qxl4', name: 'SPICE 4 monnitors'),
     OpenStruct.new(id: 'serial0', name: 'Serial terminal 0'),
     OpenStruct.new(id: 'serial1', name: 'Serial terminal 1'),
     OpenStruct.new(id: 'serial2', name: 'Serial terminal 2'),
     OpenStruct.new(id: 'serial3', name: 'Serial terminal 3')]
  end

  def get_controller(id)
    proxmox_controllers_map.find { |controller| controller.id == id }
  end

  def proxmox_max_device(id)
    options_select = get_controller(id)
    options_select ? options_select.range : 1
  end

  def proxmox_caches_map
    [OpenStruct.new(id: 'directsync', name: 'Direct sync'),
     OpenStruct.new(id: 'writethrough', name: 'Write through'),
     OpenStruct.new(id: 'writeback', name: 'Write back'),
     OpenStruct.new(id: 'unsafe', name: 'Write back unsafe'),
     OpenStruct.new(id: 'none', name: 'No cache')]
  end

  def proxmox_cpus_map
    [OpenStruct.new(id: '486', name: '486'),
     OpenStruct.new(id: 'athlon', name: 'athlon'),
     OpenStruct.new(id: 'core2duo', name: 'core2duo'),
     OpenStruct.new(id: 'coreduo', name: 'coreduo'),
     OpenStruct.new(id: 'kvm32', name: 'kvm32'),
     OpenStruct.new(id: 'kvm64', name: '(Default) kvm64'),
     OpenStruct.new(id: 'pentium', name: 'pentium'),
     OpenStruct.new(id: 'pentium2', name: 'pentium2'),
     OpenStruct.new(id: 'pentium3', name: 'pentium3'),
     OpenStruct.new(id: 'phenom', name: 'phenom'),
     OpenStruct.new(id: 'qemu32', name: 'qemu32'),
     OpenStruct.new(id: 'qemu64', name: 'qemu64'),
     OpenStruct.new(id: 'Conroe', name: 'Conroe'),
     OpenStruct.new(id: 'Penryn', name: 'Penryn'),
     OpenStruct.new(id: 'Nehalem', name: 'Nehalem'),
     OpenStruct.new(id: 'Westmere', name: 'Westmere'),
     OpenStruct.new(id: 'SandyBridge', name: 'SandyBridge'),
     OpenStruct.new(id: 'IvyBridge', name: 'IvyBridge'),
     OpenStruct.new(id: 'Haswell', name: 'Haswell'),
     OpenStruct.new(id: 'Haswell-noTSX', name: 'Haswell-noTSX'),
     OpenStruct.new(id: 'Broadwell', name: 'Broadwell'),
     OpenStruct.new(id: 'Broadwell-noTSX', name: 'Broadwell-noTSX'),
     OpenStruct.new(id: 'Skylake-Client', name: 'Skylake-Client'),
     OpenStruct.new(id: 'Opteron_G1', name: 'Opteron_G1'),
     OpenStruct.new(id: 'Opteron_G2', name: 'Opteron_G2'),
     OpenStruct.new(id: 'Opteron_G3', name: 'Opteron_G3'),
     OpenStruct.new(id: 'Opteron_G4', name: 'Opteron_G4'),
     OpenStruct.new(id: 'Opteron_G5', name: 'Opteron_G5'),
     OpenStruct.new(id: 'host', name: 'host')]
  end

  def proxmox_cpu_flags_map
    [OpenStruct.new(id: '-1', name: 'Off'),
     OpenStruct.new(id: '0', name: 'Default'),
     OpenStruct.new(id: '+1', name: 'On')]
  end

  def proxmox_scsihw_map
    [OpenStruct.new(id: 'lsi', name: 'lsi'),
     OpenStruct.new(id: 'lsi53c810', name: 'lsi53c810'),
     OpenStruct.new(id: 'megasas', name: 'megasas'),
     OpenStruct.new(id: 'virtio-scsi-pci', name: 'virtio-scsi-pci'),
     OpenStruct.new(id: 'virtio-scsi-single', name: 'virtio-scsi-single'),
     OpenStruct.new(id: 'pvscsi', name: 'pvscsi')]
  end

  def proxmox_networkcards_map
    [OpenStruct.new(id: 'e1000', name: 'Intel E1000'),
     OpenStruct.new(id: 'virtio', name: 'VirtIO (paravirtualized)'),
     OpenStruct.new(id: 'rtl8139', name: 'Realtek RTL8139'),
     OpenStruct.new(id: 'vmxnet3', name: 'VMware vmxnet3')]
  end

  def proxmox_bios_map
    [OpenStruct.new(id: 'seabios', name: '(Default) Seabios'),
     OpenStruct.new(id: 'ovmf', name: 'OVMF (UEFI)')]
  end
end
