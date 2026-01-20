import * as ProxmoxVmUtils from '../ProxmoxVmUtils';

describe('ProxmoxVmUtils', () => {
  it('exports expected helpers', () => {
    expect(ProxmoxVmUtils).toBeDefined();
    expect(typeof ProxmoxVmUtils).toBe('object');
  });
});
