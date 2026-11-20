import React from 'react';
import { render } from '@testing-library/react';
import { ProxmoxBiosProvider } from '../ProxmoxBiosContext';
import ProxmoxServerStorage from '../ProxmoxServer/ProxmoxServerStorage';

jest.mock('foremanReact/redux/API', () => ({
  API: {
    get: jest.fn(),
  },
}));

const storages = [
  {
    storage: 'local-lvm',
    node_id: 'node-a',
    content: 'images',
    avail: 100,
    used: 20,
    total: 120,
    shared: 0,
  },
  {
    storage: 'shared',
    node_id: 'node-a',
    content: 'images',
    avail: 500,
    used: 100,
    total: 600,
    shared: 1,
  },
  {
    storage: 'local-lvm',
    node_id: 'node-b',
    content: 'images',
    avail: 200,
    used: 30,
    total: 230,
    shared: 0,
  },
  {
    storage: 'shared',
    node_id: 'node-b',
    content: 'images',
    avail: 500,
    used: 100,
    total: 600,
    shared: 1,
  },
  {
    storage: 'node-b-only',
    node_id: 'node-b',
    content: 'images',
    avail: 300,
    used: 40,
    total: 340,
    shared: 0,
  },
];

describe.each([
  ['host', false, 'host[compute_attributes]'],
  ['profile', true, 'compute_attribute[vm_attrs]'],
])('%s hard disk storage choices', (_kind, fromProfile, paramScope) => {
  it('filters by the selected node and refreshes after node changes', () => {
    const field = (name, value) => ({
      name: `${paramScope}[volumes_attributes][0][${name}]`,
      value,
    });
    const storage = [
      {
        name: 'hard_disk',
        value: {
          id: field('id', 'virtio0'),
          controller: field('controller', 'virtio'),
          device: field('device', '0'),
          storage: field('storage', 'local-lvm'),
        },
      },
    ];
    const component = nodeId => (
      <ProxmoxBiosProvider>
        <ProxmoxServerStorage
          storage={storage}
          storages={storages}
          fromProfile={fromProfile}
          paramScope={paramScope}
          nodeId={nodeId}
        />
      </ProxmoxBiosProvider>
    );
    const { container, rerender } = render(component('node-a'));
    const select = container.querySelector(
      `select[name="${field('storage').name}"]`
    );
    const values = () => Array.from(select.options, option => option.value);

    expect(values()).toEqual(['local-lvm', 'shared']);
    expect(select.options[0].textContent).toBe(
      'local-lvm (free: 100 B, used: 20 B, total: 120 B)'
    );

    rerender(component('node-b'));

    expect(values()).toEqual(['local-lvm', 'shared', 'node-b-only']);
    expect(select.options[0].textContent).toBe(
      'local-lvm (free: 200 B, used: 30 B, total: 230 B)'
    );

    rerender(component('node-a'));
    expect(values()).toEqual(['local-lvm', 'shared']);
  });
});
