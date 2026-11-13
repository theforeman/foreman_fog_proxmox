import React from 'react';
import { fireEvent, render, waitFor } from '@testing-library/react';
import { API } from 'foremanReact/redux/API';
import { ProxmoxBiosProvider } from '../ProxmoxBiosContext';
import HardDisk from '../ProxmoxServer/components/HardDisk';
import EFIDisk from '../ProxmoxServer/components/EFIDisk';
import CDRom from '../ProxmoxServer/components/CDRom';
import ProxmoxContainerStorage from '../ProxmoxContainer/ProxmoxContainerStorage';
import ProxmoxContainerOptions from '../ProxmoxContainer/ProxmoxContainerOptions';

jest.mock('foremanReact/redux/API', () => ({
  API: { get: jest.fn() },
}));

const storages = [
  ['local', 'iso,vztmpl,backup'],
  ['disks', 'images'],
  ['containers', 'rootdir'],
  ['mixed', 'images,rootdir,iso,vztmpl'],
  ['backups', 'backup'],
].map(([storage, content]) => ({
  storage,
  content,
  node_id: 'node-a',
  avail: 100,
  used: 100,
  total: 200,
}));

const fields = values =>
  Object.fromEntries(
    Object.entries(values).map(([name, value]) => [
      name,
      { name: `vm[${name}]`, value },
    ])
  );

const choices = select =>
  Array.from(select.options, option => option.value).filter(Boolean);

describe('storage content filtering', () => {
  it('offers only disk-image storage for QEMU hard disks', () => {
    const { container } = render(
      <HardDisk
        id={0}
        data={fields({
          storage: 'disks',
          controller: 'virtio',
          device: '0',
          id: 'virtio0',
          size: 8,
          volid: '',
        })}
        storages={storages}
        nodeId="node-a"
        updateHardDiskData={jest.fn()}
        createUniqueDevice={jest.fn()}
        validateDevice={jest.fn()}
      />
    );

    expect(
      choices(container.querySelector('select[name="vm[storage]"]'))
    ).toEqual(['disks', 'mixed']);
  });

  it('offers only disk-image storage for EFI disks', () => {
    const { container } = render(
      <ProxmoxBiosProvider initialBios="ovmf">
        <EFIDisk
          data={fields({
            storage: 'disks',
            volid: 'disks:0',
            format: 'raw',
            preEnrolledKeys: '0',
            id: 0,
          })}
          storages={storages}
          nodeId="node-a"
          vmId="100"
          onRemove={jest.fn()}
        />
      </ProxmoxBiosProvider>
    );

    expect(
      choices(container.querySelector('select[name="vm[storage]"]'))
    ).toEqual(['disks', 'mixed']);
  });

  it('offers only container storage for rootfs and new mount points', () => {
    const { container, getByRole } = render(
      <ProxmoxContainerStorage
        storages={storages}
        nodeId="node-a"
        paramScope="vm"
      />
    );

    fireEvent.click(getByRole('button', { name: 'Add MountPoint' }));
    const selects = container.querySelectorAll('select[name$="[storage]"]');
    expect(selects).toHaveLength(2);
    selects.forEach(select =>
      expect(choices(select)).toEqual(['containers', 'mixed'])
    );
  });

  it.each([
    ['iso', 'local:iso/debian.iso'],
    ['vztmpl', 'local:vztmpl/debian.tar.zst'],
  ])('offers %s-only storage and loads its media', async (content, volid) => {
    API.get.mockResolvedValue({ data: [{ content, volid }] });
    const data = fields({
      storage: 'local',
      volid: '',
      cdrom: 'image',
      storageType: 'cdrom',
      ostemplateStorage: 'local',
      ostemplateFile: '',
    });
    const { container } = render(
      content === 'iso' ? (
        <CDRom
          data={data}
          storages={storages}
          nodeId="node-a"
          computeResourceId={1}
          canAttachCdromImage
          onRemove={jest.fn()}
        />
      ) : (
        <ProxmoxContainerOptions
          options={data}
          storages={storages}
          nodeId="node-a"
          computeResourceId={1}
          fromProfile
        />
      )
    );

    const storageName = content === 'iso' ? 'storage' : 'ostemplateStorage';
    const mediaName = content === 'iso' ? 'volid' : 'ostemplateFile';
    expect(
      choices(container.querySelector(`select[name="vm[${storageName}]"]`))
    ).toEqual(['local', 'mixed']);
    await waitFor(() =>
      expect(
        choices(container.querySelector(`select[name="vm[${mediaName}]"]`))
      ).toEqual([volid])
    );
    expect(API.get).toHaveBeenCalledWith(
      '/foreman_fog_proxmox/volumes/1/node-a/local'
    );
  });
});
