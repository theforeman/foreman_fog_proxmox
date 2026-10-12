/* eslint-disable max-lines */
import React from 'react';
import { act, fireEvent, render, waitFor } from '@testing-library/react';
import { API } from 'foremanReact/redux/API';
import { ProxmoxBiosProvider } from '../ProxmoxBiosContext';
import { ResourceAvailabilityContext } from '../common/ResourceSelect';
import ServerNetwork from '../ProxmoxServer/ProxmoxServerNetwork';
import ContainerNetwork from '../ProxmoxContainer/ProxmoxContainerNetwork';
import ContainerStorage from '../ProxmoxContainer/ProxmoxContainerStorage';
import MountPoint from '../ProxmoxContainer/MountPoint';
import ContainerOptions from '../ProxmoxContainer/ProxmoxContainerOptions';
import EFIDisk from '../ProxmoxServer/components/EFIDisk';
import CDRom from '../ProxmoxServer/components/CDRom';
import GeneralTabContent from '../GeneralTabContent';

jest.mock('foremanReact/redux/API', () => ({ API: { get: jest.fn() } }));

const field = (name, value) => ({ name, value });
const storages = ['node-a', 'node-b'].map(node => ({
  storage: node === 'node-a' ? 'saved' : 'other',
  node_id: node,
  content: 'images,rootdir,iso,vztmpl',
  avail: 100,
  used: 100,
  total: 200,
}));
const efiData = {
  id: field('efi[id]', 0),
  storage: field('storage', 'saved'),
  volid: field('efi[volid]', 'saved:100'),
  format: field('efi[format]', 'raw'),
  preEnrolledKeys: field('efi[pre_enrolled_keys]', '0'),
};
const disk = {
  id: field('id', 'rootfs'),
  storage: field('storage', 'saved'),
  size: field('size', 8),
};
const disks = [{ name: 'rootfs', value: disk }];
const network = [
  {
    value: {
      id: field('id', 'net0'),
      model: field('model', 'virtio'),
      name: field('name', 'eth0'),
      bridge: field('bridge', 'saved'),
      dhcp: field('dhcp', '0'),
      dhcp6: field('dhcp6', '0'),
    },
  },
];
const general = {
  type: field('type', 'qemu'),
  nodeId: field('node', 'node-a'),
  isoUploadStorage: field('storage', 'saved'),
};

describe('dependent resource fields', () => {
  it.each([
    [
      'QEMU bridge',
      'bridge',
      node => (
        <ServerNetwork
          network={network}
          bridges={[{ iface: node === 'node-a' ? 'saved' : 'other' }]}
        />
      ),
    ],
    [
      'LXC bridge',
      'bridge',
      node => (
        <ContainerNetwork
          network={network}
          bridges={[{ iface: node === 'node-a' ? 'saved' : 'other' }]}
        />
      ),
    ],
    [
      'EFI storage',
      'storage',
      node => (
        <ProxmoxBiosProvider initialBios="ovmf">
          <EFIDisk
            data={efiData}
            storages={storages}
            nodeId={node}
            vmId="100"
            onRemove={jest.fn()}
          />
        </ProxmoxBiosProvider>
      ),
    ],
    [
      'rootfs storage',
      'storage',
      node => (
        <ContainerStorage storage={disks} storages={storages} nodeId={node} />
      ),
    ],
    [
      'mount-point storage',
      'storage',
      node => (
        <MountPoint
          id={0}
          data={disk}
          storagesMap={[
            { value: node === 'node-a' ? 'saved' : 'other', label: node },
          ]}
        />
      ),
    ],
    [
      'ISO upload storage',
      'storage',
      node => (
        <GeneralTabContent
          general={{ ...general, nodeId: field('node', node) }}
          storages={storages}
          newVm
          provisionMethod="image"
          nodesMap={[{ value: node, label: node }]}
          handleChange={jest.fn()}
        />
      ),
    ],
  ])(
    '%s preserves, invalidates and restores the submitted selection',
    (_label, name, component) => {
      const wrapper = (node, availability = 'ready') => (
        <form>
          <ResourceAvailabilityContext.Provider
            value={node ? availability : 'parent'}
          >
            {component(node)}
          </ResourceAvailabilityContext.Provider>
        </form>
      );
      const { container, rerender } = render(wrapper('node-a'));
      const select = () => container.querySelector(`select[name="${name}"]`);
      const serialized = () =>
        new FormData(container.querySelector('form')).get(name);
      expect(select().value).toBe('saved');
      rerender(wrapper(''));
      expect(select().value).toBe('saved');
      expect(select().selectedOptions[0].textContent).not.toContain(
        'unavailable'
      );
      expect(select().validationMessage).toBe(
        'Select a node to check resource availability.'
      );
      rerender(wrapper('node-a'));
      expect(select().checkValidity()).toBe(true);
      rerender(wrapper('node-b', 'loading'));
      expect(select().value).toBe('saved');
      expect(serialized()).toBe('saved');
      expect(select().selectedOptions[0].textContent).not.toContain(
        'unavailable'
      );
      expect(select().checkValidity()).toBe(false);
      rerender(wrapper('node-b', 'error'));
      expect(select().validationMessage).toContain('could not be checked');
      rerender(wrapper('node-b'));
      expect(select().value).toBe('saved');
      expect(select().selectedOptions[0].textContent).toContain('unavailable');
      expect(serialized()).toBe('saved');
      expect(select().checkValidity()).toBe(false);
      rerender(wrapper('node-a'));
      expect(select().checkValidity()).toBe(true);
      expect(select().value).toBe('saved');
    }
  );

  it.each([ServerNetwork, ContainerNetwork])(
    'retains an explicit bridge replacement through node changes',
    Component => {
      const wrapper = bridges => (
        <Component
          network={network}
          bridges={bridges.map(iface => ({ iface }))}
        />
      );
      const { container, rerender } = render(wrapper(['other']));
      const select = container.querySelector('select[name="bridge"]');
      fireEvent.change(select, { target: { value: 'other' } });
      expect(select.value).toBe('other');
      expect(select.checkValidity()).toBe(true);
      rerender(wrapper(['saved']));
      expect(select.value).toBe('other');
      expect(select.checkValidity()).toBe(false);
      rerender(wrapper(['other']));
      expect(select.checkValidity()).toBe(true);
      fireEvent.change(select, { target: { value: '' } });
      expect(select.value).toBe('');
      expect(select.checkValidity()).toBe(true);
    }
  );
});

describe('dependent media requests', () => {
  beforeEach(() => API.get.mockReset());
  const cdrom = {
    cdrom: field('media', 'image'),
    storage: field('storage', 'saved'),
    volid: field('volume', 'saved:iso/image.iso'),
    storageType: field('storage_type', 'cdrom'),
  };
  const template = {
    ostemplateStorage: field('storage', 'saved'),
    ostemplateFile: field('volume', 'saved:iso/image.iso'),
  };
  const bothNodes = storages.map(storage => ({ ...storage, storage: 'saved' }));
  it.each(['iso', 'vztmpl'])(
    '%s distinguishes a failed lookup from an empty list before a volume is selected',
    async content => {
      const pending = [];
      API.get.mockImplementation(
        () =>
          new Promise((resolve, reject) => pending.push({ resolve, reject }))
      );
      const component = node =>
        content === 'iso' ? (
          <CDRom
            data={{ ...cdrom, volid: field('volume', '') }}
            storages={bothNodes}
            nodeId={node}
            computeResourceId={1}
            canAttachCdromImage
            onRemove={jest.fn()}
          />
        ) : (
          <ContainerOptions
            options={{ ...template, ostemplateFile: field('volume', '') }}
            storages={bothNodes}
            nodeId={node}
            computeResourceId={1}
            newVm
          />
        );
      const { container, rerender } = render(component('node-a'));
      const select = container.querySelector('[name="volume"]');
      const errorMessage = () =>
        select.closest('.form-group').querySelector('.error-message');
      expect(select.value).toBe('');
      expect(errorMessage()).not.toHaveTextContent('could not be checked');
      await act(async () => pending[0].reject(new Error('lookup failed')));
      expect(select.value).toBe('');
      expect(select.checkValidity()).toBe(false);
      expect(select.validationMessage).toContain('could not be checked');
      expect(errorMessage()).toHaveTextContent(
        'Resource availability could not be checked. Reload the form to retry.'
      );
      expect(select.textContent).not.toContain('unavailable');

      rerender(component('node-b'));
      expect(errorMessage()).not.toHaveTextContent('could not be checked');
      await act(async () => pending[1].resolve({ data: [] }));
      expect(errorMessage()).toHaveTextContent('Select a resource.');
      expect(select.checkValidity()).toBe(false);

      rerender(component('node-a'));
      await act(async () =>
        pending[2].resolve({ data: [{ volid: cdrom.volid.value, content }] })
      );
      fireEvent.change(select, { target: { value: cdrom.volid.value } });
      expect(select.checkValidity()).toBe(true);
      expect(errorMessage()).toBeNull();
    }
  );

  it.each(['iso', 'vztmpl'])(
    '%s waits for a node without fetching or discarding saved media',
    content => {
      const { container } = render(
        <ResourceAvailabilityContext.Provider value="parent">
          {content === 'iso' ? (
            <CDRom
              data={cdrom}
              storages={storages}
              nodeId=""
              computeResourceId={1}
              canAttachCdromImage
              onRemove={jest.fn()}
            />
          ) : (
            <ContainerOptions
              options={template}
              storages={storages}
              nodeId=""
              computeResourceId={1}
              newVm
            />
          )}
        </ResourceAvailabilityContext.Provider>
      );
      expect(API.get).not.toHaveBeenCalled();
      const storage = container.querySelector('[name="storage"]');
      const volume = container.querySelector('[name="volume"]');
      expect(storage.value).toBe('saved');
      expect(volume.value).toBe(cdrom.volid.value);
      [storage, volume].forEach(select => {
        expect(select.validationMessage).toBe(
          'Select a node to check resource availability.'
        );
        expect(select.selectedOptions[0].textContent).not.toContain(
          'unavailable'
        );
      });
    }
  );
  it.each(['iso', 'vztmpl'])(
    '%s storage remains selected when missing and explicit replacement clears the dependent volume',
    async content => {
      API.get.mockResolvedValue({
        data: [{ volid: 'saved:iso/image.iso', content }],
      });
      const component = node =>
        content === 'iso' ? (
          <CDRom
            data={cdrom}
            storages={storages}
            nodeId={node}
            computeResourceId={1}
            canAttachCdromImage
            onRemove={jest.fn()}
          />
        ) : (
          <ContainerOptions
            options={template}
            storages={storages}
            nodeId={node}
            computeResourceId={1}
            newVm
          />
        );
      const { container, rerender } = render(component('node-a'));
      const storage = container.querySelector('select[name="storage"]');
      const volume = () => container.querySelector('select[name="volume"]');
      await waitFor(() => expect(volume().checkValidity()).toBe(true));
      rerender(component('node-b'));
      expect(storage.value).toBe('saved');
      expect(storage.checkValidity()).toBe(false);
      await waitFor(() =>
        expect(volume().validationMessage).not.toContain('loading')
      );
      fireEvent.change(storage, { target: { value: 'other' } });
      expect(storage.value).toBe('other');
      expect(storage.checkValidity()).toBe(true);
      expect(volume().value).toBe('');
      await waitFor(() =>
        expect(volume().validationMessage).not.toContain('loading')
      );
      expect(volume().checkValidity()).toBe(false);
    }
  );

  it('ignores a late ISO response for the previous node', async () => {
    const pending = [];
    API.get.mockImplementation(
      () => new Promise(resolve => pending.push(resolve))
    );
    const component = node => (
      <CDRom
        data={cdrom}
        storages={bothNodes}
        nodeId={node}
        computeResourceId={1}
        canAttachCdromImage
        onRemove={jest.fn()}
      />
    );
    const { container, rerender } = render(component('node-a'));
    rerender(component('node-b'));
    await act(async () => pending[1]({ data: [] }));
    const select = container.querySelector('select[name="volume"]');
    expect(select.checkValidity()).toBe(false);
    await act(async () =>
      pending[0]({ data: [{ volid: cdrom.volid.value, content: 'iso' }] })
    );
    expect(select.checkValidity()).toBe(false);
    expect(select.selectedOptions[0].textContent).toContain('unavailable');
  });

  it.each(['iso', 'vztmpl'])(
    '%s preserves the volume while loading and after a failed or empty lookup',
    async content => {
      const pending = [];
      API.get.mockImplementation(
        () =>
          new Promise((resolve, reject) => pending.push({ resolve, reject }))
      );
      const wrapper = node => (
        <form>
          {content === 'iso' ? (
            <CDRom
              data={cdrom}
              storages={bothNodes}
              nodeId={node}
              computeResourceId={1}
              canAttachCdromImage
              onRemove={jest.fn()}
            />
          ) : (
            <ContainerOptions
              options={template}
              storages={bothNodes}
              nodeId={node}
              computeResourceId={1}
              newVm
            />
          )}
        </form>
      );
      const { container, rerender } = render(wrapper('node-a'));
      const select = () => container.querySelector('select[name="volume"]');
      expect(select().value).toBe('saved:iso/image.iso');
      expect(select().validationMessage).toContain('loading');
      expect(new FormData(container.querySelector('form')).get('volume')).toBe(
        'saved:iso/image.iso'
      );
      await act(async () =>
        pending[0].resolve({
          data: [{ volid: 'saved:iso/image.iso', content }],
        })
      );
      expect(select().checkValidity()).toBe(true);
      rerender(wrapper('node-b'));
      expect(select().validationMessage).toContain('loading');
      await act(async () => pending[1].reject(new Error('lookup failed')));
      expect(select().validationMessage).toContain('could not be checked');
      expect(select().selectedOptions[0].textContent).not.toContain(
        'unavailable'
      );
      rerender(wrapper('node-a'));
      await act(async () => pending[2].resolve({ data: [] }));
      expect(select().selectedOptions[0].textContent).toContain('unavailable');
      expect(select().checkValidity()).toBe(false);
      rerender(wrapper('node-b'));
      await act(async () =>
        pending[3].resolve({
          data: [{ volid: 'saved:iso/image.iso', content }],
        })
      );
      await waitFor(() => expect(select().checkValidity()).toBe(true));
    }
  );

  it('does not validate ISO selections for an empty drive or a removed disk', async () => {
    API.get.mockResolvedValue({ data: [] });
    const component = (media, hidden = false) => (
      <CDRom
        key={media}
        data={{ ...cdrom, cdrom: field('media', media) }}
        storages={[]}
        nodeId="node-a"
        computeResourceId={1}
        canAttachCdromImage
        onRemove={jest.fn()}
        hidden={hidden}
      />
    );
    const { container, rerender } = render(component('none'));
    expect(container.querySelector('select')).toBeNull();
    rerender(component('image', true));
    await waitFor(() => expect(API.get).toHaveBeenCalled());
    expect(
      container.querySelector('select[name="storage"]').validationMessage
    ).toBe('');
    expect(
      container.querySelector('select[name="volume"]').validationMessage
    ).toBe('');
  });
});
