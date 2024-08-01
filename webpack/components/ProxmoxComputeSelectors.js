const ProxmoxComputeSelectors = {
  proxmoxTypesMap: [
    { value: 'qemu', label: 'KVM/Qemu server' },
    { value: 'lxc', label: 'LXC container' },
  ],

  proxmoxControllersCloudinitMap: [
    { value: 'ide', label: 'IDE' },
    { value: 'sata', label: 'SATA' },
    { value: 'scsi', label: 'SCSI' },
  ],

  proxmoxScsiControllersMap: [
    { value: 'lsi', label: 'LSI 53C895A (Default)' },
    { value: 'lsi53c810', label: 'LSI 53C810' },
    { value: 'virtio-scsi-pci', label: 'VirtIO SCSI' },
    { value: 'virtio-scsi-single', label: 'VirtIO SCSI Single' },
    { value: 'megasas', label: 'MegaRAID SAS 8708EM2' },
    { value: 'pvscsi', label: 'VMware PVSCSI' },
  ],

  proxmoxArchsMap: [
    { value: 'amd64', label: '64 bits' },
    { value: 'i386', label: '32 bits' },
  ],

  proxmoxOstypesMap: [
    { value: 'debian', label: 'Debian' },
    { value: 'ubuntu', label: 'Ubuntu' },
    { value: 'centos', label: 'CentOS' },
    { value: 'fedora', label: 'Fedora' },
    { value: 'opensuse', label: 'OpenSuse' },
    { value: 'archlinux', label: 'ArchLinux' },
    { value: 'gentoo', label: 'Gentoo' },
    { value: 'alpine', label: 'Alpine' },
    { value: 'unmanaged', label: 'Unmanaged' },
  ],

  proxmoxOperatingSystemsMap: [
    { value: 'other', label: 'Unspecified OS' },
    { value: 'wxp', label: 'Microsoft Windows XP' },
    { value: 'w2k', label: 'Microsoft Windows 2000' },
    { value: 'w2k3', label: 'Microsoft Windows 2003' },
    { value: 'w2k8', label: 'Microsoft Windows 2008' },
    { value: 'wvista', label: 'Microsoft Windows Vista' },
    { value: 'win7', label: 'Microsoft Windows 7' },
    { value: 'win8', label: 'Microsoft Windows 8/2012/2012r2' },
    { value: 'win10', label: 'Microsoft Windows 10/2016' },
    { value: 'l24', label: 'Linux 2.4 Kernel' },
    { value: 'l26', label: 'Linux 2.6/3.X + Kernel' },
    { value: 'solaris', label: 'Solaris/OpenSolaris/OpenIndiania kernel' },
  ],

  proxmoxVgasMap: [
    { value: '', labal: '' },
    { value: 'std', label: 'Standard VGA' },
    { value: 'vmware', label: 'Vmware compatible' },
    { value: 'qxl', label: 'SPICE' },
    { value: 'qxl2', label: 'SPICE 2 monitors' },
    { value: 'qxl3', label: 'SPICE 3 monitors' },
    { value: 'qxl4', label: 'SPICE 4 monitors' },
    { value: 'serial0', label: 'Serial terminal 0' },
    { value: 'serial1', label: 'Serial terminal 1' },
    { value: 'serial2', label: 'Serial terminal 2' },
    { value: 'serial3', label: 'Serial terminal 3' },
  ],

  proxmoxCachesMap: [
    { value: '', labal: '' },
    { value: 'directsync', label: 'Direct sync' },
    { value: 'writethrough', label: 'Write through' },
    { value: 'writeback', label: 'Write back' },
    { value: 'unsafe', label: 'Write back unsafe' },
    { value: 'none', label: 'No cache' },
  ],

  proxmoxCpusMap: [
    { value: '486', label: '486' },
    { value: 'athlon', label: 'athlon' },
    { value: 'core2duo', label: 'core2duo' },
    { value: 'coreduo', label: 'coreduo' },
    { value: 'kvm32', label: 'kvm32' },
    { value: 'kvm64', label: '(Default) kvm64' },
    { value: 'pentium', label: 'pentium' },
    { value: 'pentium2', label: 'pentium2' },
    { value: 'pentium3', label: 'pentium3' },
    { value: 'phenom', label: 'phenom' },
    { value: 'qemu32', label: 'qemu32' },
    { value: 'qemu64', label: 'qemu64' },
    { value: 'Conroe', label: 'Conroe' },
    { value: 'Penryn', label: 'Penryn' },
    { value: 'Nehalem', label: 'Nehalem' },
    { value: 'Westmere', label: 'Westmere' },
    { value: 'SandyBridge', label: 'SandyBridge' },
    { value: 'IvyBridge', label: 'IvyBridge' },
    { value: 'Haswell', label: 'Haswell' },
    { value: 'Haswell-noTSX', label: 'Haswell-noTSX' },
    { value: 'Broadwell', label: 'Broadwell' },
    { value: 'Broadwell-noTSX', label: 'Broadwell-noTSX' },
    { value: 'Skylake-Client', label: 'Skylake-Client' },
    { value: 'Opteron_G1', label: 'Opteron_G1' },
    { value: 'Opteron_G2', label: 'Opteron_G2' },
    { value: 'Opteron_G3', label: 'Opteron_G3' },
    { value: 'Opteron_G4', label: 'Opteron_G4' },
    { value: 'Opteron_G5', label: 'Opteron_G5' },
    { value: 'host', label: 'host' },
  ],

  proxmoxCpuFlagsMap: [
    { value: '-1', label: 'Off' },
    { value: '0', label: 'Default' },
    { value: '+1', label: 'On' },
  ],

  proxmoxScsihwMap: [
    { value: 'lsi', label: 'lsi' },
    { value: 'lsi53c810', label: 'lsi53c810' },
    { value: 'megasas', label: 'megasas' },
    { value: 'virtio-scsi-pci', label: 'virtio-scsi-pci' },
    { value: 'virtio-scsi-single', label: 'virtio-scsi-single' },
    { value: 'pvscsi', label: 'pvscsi' },
  ],

  proxmoxNetworkcardsMap: [
    { value: 'e1000', label: 'Intel E1000' },
    { value: 'virtio', label: 'VirtIO (paravirtualized)' },
    { value: 'rtl8139', label: 'Realtek RTL8139' },
    { value: 'vmxnet3', label: 'VMware vmxnet3' },
  ],

  proxmoxBiosMap: [
    { value: 'seabios', label: '(Default) Seabios' },
    { value: 'ovmf', label: 'OVMF (UEFI)' },
  ],
};

ProxmoxComputeSelectors.proxmoxControllersHDDMap = [
  ...ProxmoxComputeSelectors.proxmoxControllersCloudinitMap,
  { value: 'virtio', label: 'VirtIO Block' },
];

export default ProxmoxComputeSelectors;
