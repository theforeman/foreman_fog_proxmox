import React from 'react';
import { fireEvent, render } from '@testing-library/react';
import ServerInterface from '../ProxmoxServer/components/NetworkInterface';
import ContainerInterface from '../ProxmoxContainer/components/NetworkInterface';
import ProxmoxContainerNetwork from '../ProxmoxContainer/ProxmoxContainerNetwork';

describe.each([
  ['qemu', ServerInterface],
  ['lxc', ContainerInterface],
])('%s interface bridge preservation', (type, Component) => {
  const field = (name, value) => ({
    name: `compute_attribute[vm_attrs][interfaces_attributes][0][${name}]`,
    value,
  });

  const data = {
    id: field('id', 'net0'),
    model: field('model', 'virtio'),
    name: field('name', 'eth0'),
    bridge: field('bridge', 'vmbr9'),
    dhcp: field('dhcp', '0'),
    dhcp6: field('dhcp6', '0'),
  };

  it('submits the saved bridge before metadata loads, after refresh, and after changing nodes', () => {
    const updateNetworkData = jest.fn();
    const props = { id: 0, data, updateNetworkData };
    const { container, rerender } = render(
      <form>
        <Component {...props} bridges={[]} />
      </form>
    );
    const form = container.querySelector('form');
    const bridgeSelect = form.querySelector(
      `select[name="${data.bridge.name}"]`
    );
    expect(new FormData(form).get(data.bridge.name)).toBe('vmbr9');

    rerender(
      <form>
        <Component
          {...props}
          bridges={[{ iface: 'vmbr0' }, { iface: 'vmbr9' }]}
        />
      </form>
    );
    expect(bridgeSelect).toHaveValue('vmbr9');
    expect(new FormData(form).get(data.bridge.name)).toBe('vmbr9');

    rerender(
      <form>
        <Component {...props} bridges={[{ iface: 'vmbr1' }]} />
      </form>
    );
    expect(bridgeSelect).toHaveValue('vmbr9');
    expect(bridgeSelect.selectedOptions[0].textContent).toBe(
      'vmbr9 (unavailable)'
    );
    expect(updateNetworkData).not.toHaveBeenCalled();

    fireEvent.change(bridgeSelect, { target: { value: 'vmbr1' } });
    expect(new FormData(form).get(data.bridge.name)).toBe('vmbr1');
    expect(updateNetworkData).toHaveBeenCalledWith(
      0,
      expect.objectContaining({ bridge: field('bridge', 'vmbr1') })
    );
  });

  it('does not attach an intentionally unbridged NIC to the first bridge', () => {
    const { container } = render(
      <form>
        <Component
          id={0}
          data={{ ...data, bridge: field('bridge', '') }}
          bridges={[{ iface: 'vmbr0' }]}
        />
      </form>
    );
    expect(
      new FormData(container.querySelector('form')).get(data.bridge.name)
    ).toBe('');
  });
});

it('refreshes bridges on an existing container profile NIC after metadata or placement changes', () => {
  const scope = 'compute_attribute[vm_attrs][interfaces_attributes][0]';
  const network = [
    {
      value: {
        id: { name: `${scope}[id]`, value: 'net0' },
        name: { name: `${scope}[name]`, value: 'eth0' },
        bridge: { name: `${scope}[bridge]`, value: 'vmbr9' },
      },
    },
  ];
  const { container, rerender } = render(
    <ProxmoxContainerNetwork network={network} bridges={[]} />
  );
  const select = container.querySelector(`select[name="${scope}[bridge]"]`);
  expect(select).toHaveValue('vmbr9');

  rerender(
    <ProxmoxContainerNetwork
      network={network}
      bridges={[{ iface: 'vmbr0' }, { iface: 'vmbr9' }]}
    />
  );
  expect(Array.from(select.options, option => option.value)).toEqual([
    '',
    'vmbr0',
    'vmbr9',
  ]);
  expect(select).toHaveValue('vmbr9');
});
