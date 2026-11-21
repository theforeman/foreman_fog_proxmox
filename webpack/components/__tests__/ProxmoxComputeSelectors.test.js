import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';

describe('ProxmoxComputeSelectors', () => {
  it('exports expected base maps', () => {
    expect(ProxmoxComputeSelectors).toBeDefined();

    expect(Array.isArray(ProxmoxComputeSelectors.proxmoxTypesMap)).toBe(true);
    expect(Array.isArray(ProxmoxComputeSelectors.proxmoxCpusMap)).toBe(true);
    expect(Array.isArray(ProxmoxComputeSelectors.proxmoxBiosMap)).toBe(true);
  });

  it('contains known Proxmox types', () => {
    const values = ProxmoxComputeSelectors.proxmoxTypesMap.map(v => v.value);

    expect(values).toContain('qemu');
    expect(values).toContain('lxc');
  });

  it("doesn't contain empty Proxmox types", () => {
    const values = ProxmoxComputeSelectors.proxmoxTypesMap.map(v => v.value);

    expect(values).not.toContain('');
  });

  it('contains the supported LXC architectures', () => {
    expect(ProxmoxComputeSelectors.proxmoxArchsMap).toEqual([
      { value: 'amd64', label: 'amd64 (64-bit x86)' },
      { value: 'i386', label: 'i386 (32-bit x86)' },
      { value: 'arm64', label: 'arm64 (64-bit ARM)' },
      { value: 'armhf', label: 'armhf (32-bit ARM)' },
    ]);
  });

  it('builds HDD controllers map from cloudinit controllers plus virtio', () => {
    const cloudinitValues = ProxmoxComputeSelectors.proxmoxControllersCloudinitMap.map(
      v => v.value
    );

    const hddValues = ProxmoxComputeSelectors.proxmoxControllersHDDMap.map(
      v => v.value
    );

    cloudinitValues.forEach(value => {
      expect(hddValues).toContain(value);
    });

    expect(hddValues).toContain('virtio');
  });
});
