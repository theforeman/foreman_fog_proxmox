import React, { useState, useEffect, useCallback } from 'react';
import PropTypes from 'prop-types';
import { Title, PageSection, Button } from '@patternfly/react-core';
import { TimesIcon } from '@patternfly/react-icons';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import HardDisk from './components/HardDisk';
import CDRom from './components/CDRom';
import EFIDisk from './components/EFIDisk';
import { setEfiDiskVolId } from '../ProxmoxVmUtils';

const ProxmoxServerStorage = ({ storage, efidisk, storages, nodeId, vmId, paramScope }) => {
  const [hardDisks, setHardDisks] = useState([]);
  const [nextId, setNextId] = useState(0);
  const [cdRom, setCdRom] = useState(false);
  const [cdRomData, setCdRomData] = useState(null);
  const [efiDisk, setEfiDisk] = useState(false);
  const [efiDiskData, setEfiDiskData] = useState(null);
  const [nextDeviceNumbers, setNextDeviceNumbers] = useState({
    ide: 0,
    sata: 0,
    scsi: 0,
    virtio: 0,
  });
  const controllerRanges = {
    ide: { min: 0, max: 3 },
    sata: { min: 0, max: 5 },
    scsi: { min: 0, max: 30 },
    virtio: { min: 0, max: 15 },
  };

  useEffect(() => {
    if (storage?.length > 0) {
      const updatedCounts = { ...nextDeviceNumbers };
      storage.forEach(disk => {
        if (disk.name === 'hard_disk') {
          const controller = disk.value.controller.value;
          const device = parseInt(disk.value.device.value, 10);
          if (device >= updatedCounts[controller]) {
            updatedCounts[controller] = device + 1;
          }
          addHardDisk(null, disk.value, true);
        }
        if (disk.name === 'cdrom') {
          addCDRom(null, disk.value, true);
        }
      });
      setNextDeviceNumbers(updatedCounts);
    }
    if (efidisk && Object.keys(efidisk).length > 0) {
      addEfiDisk(null, efidisk, true);
    }
  }, [storage, efidisk]);

  const getNextDevice = useCallback(
    (controller, type = null) => {
      const isDevice2Reserved = controller === 'ide' && type !== 'cdrom';
      for (
        let i = controllerRanges[controller].min;
        i <= controllerRanges[controller].max;
        i++
      ) {
        if (!(isDevice2Reserved && i === 2)) {
          if (
            !hardDisks.some(
              disk =>
                disk.data.controller.value === controller &&
                disk.data.device.value === i
            )
          ) {
            return i;
          }
        }
      }
      return null;
    },
    [hardDisks, controllerRanges]
  );

  const createUniqueDevice = useCallback(
    (type, selectedController = 'virtio') => {
      let controller = selectedController;
      if (type === 'cdrom') {
        controller = 'ide';
        return { controller, device: 2, id: 'ide2' };
      }

      const device = getNextDevice(controller, type);
      if (device !== null) {
        const id = `${controller}${device}`;
        const newCounts = {
          ...nextDeviceNumbers,
          [controller]: nextDeviceNumbers[controller] + 1,
        };
        setNextDeviceNumbers(newCounts);
        return { controller, device, id };
      }
      return null;
    },
    [getNextDevice, nextDeviceNumbers]
  );

  const addHardDisk = useCallback(
    (event, initialData = null, isPreExisting = false) => {
      if (event) event.preventDefault();
      let deviceInfo = null;
      if (!isPreExisting) {
        const selectedController = initialData?.controller?.value || 'virtio';
        deviceInfo = createUniqueDevice('hard_disk', selectedController);
        if (!deviceInfo) return;
      }
      const { controller, device, id } = deviceInfo || {};
      const initHdd = initialData || {
        id: {
          name: `${paramScope}[volumes_attributes][${nextId}][id]`,
          value: id,
        },
        device: {
          name: `${paramScope}[volumes_attributes][${nextId}][device]`,
          value: device,
        },
        storageType: {
          name: `${paramScope}[volumes_attributes][${nextId}][storage_type]`,
          value: 'hard_disk',
        },
        storage: {
          name: `${paramScope}[volumes_attributes][${nextId}][storage]`,
          value: 'local',
        },
        cache: {
          name: `${paramScope}[volumes_attributes][${nextId}][cache]`,
          value: null,
        },
        size: {
          name: `${paramScope}[volumes_attributes][${nextId}][size]`,
          value: 8,
        },
        controller: {
          name: `${paramScope}[volumes_attributes][${nextId}][controller]`,
          value: controller,
        },
      };

      setNextId(prevNextId => {
        const newNextId = prevNextId + 1;
        const newHardDisk = {
          id: newNextId,
          storages,
          data: initHdd,
          disks: storage,
          isNew: !isPreExisting,
        };
        setHardDisks(prevHardDisks => [...prevHardDisks, newHardDisk]);
        return newNextId;
      });
    },
    [nextId, paramScope, storage, storages, createUniqueDevice]
  );

  const removeHardDisk = idToRemove => {
    const newHardDisks = hardDisks
      .filter(hardDisk => !(hardDisk.id === idToRemove && hardDisk.isNew))
      .map(hardDisk =>
        hardDisk.id === idToRemove ? { ...hardDisk, hidden: true } : hardDisk
      );
    setHardDisks(newHardDisks);
  };

  const updateHardDiskData = (id, updatedData) => {
    setHardDisks(
      hardDisks.map(disk =>
        disk.id === id ? { ...disk, data: updatedData } : disk
      )
    );
  };

  const addCDRom = useCallback(
    (event, initialData = null, isPreExisting = false) => {
      if (event) event.preventDefault();
      if (!initialData && cdRom) return;

      const deviceInfo = initialData
        ? { controller: 'ide', device: 2, id: 'ide2' }
        : createUniqueDevice('cdrom');
      if (!deviceInfo) return;

      const initCDRom = initialData || {
        id: {
          name: `${paramScope}[volumes_attributes][${nextId}][id]`,
          value: deviceInfo.id,
        },
        volid: {
          name: `${paramScope}[volumes_attributes][${nextId}][volid]`,
          value: '',
        },
        storageType: {
          name: `${paramScope}[volumes_attributes][${nextId}][storageType]`,
          value: 'cdrom',
        },
        storage: {
          name: `${paramScope}[volumes_attributes][${nextId}][storage]`,
          value: 'local',
        },
        cdrom: {
          name: `${paramScope}[volumes_attributes][${nextId}][cdrom]`,
          value: '',
        },
      };
      setCdRom(true);
      setCdRomData(initCDRom);
    },
    [cdRom, nextId, paramScope, createUniqueDevice]
  );

  const removeCDRom = () => {
    setCdRom(false);
  };

  const addEfiDisk = useCallback(
    (event, initialData = null, isPreExisting = false) => {
      if (event) event.preventDefault();
      if (!initialData && efiDisk) return;

      const initEfiDisk = initialData || {
        id: {
          name: `${paramScope}[efidisk_attributes][id]`,
          value: 0, // there is only one efi disk allowed
        },
        volid: {
          name: `${paramScope}[efidisk_attributes][volid]`,
          value: '',
        },
        storage: {
          name: `${paramScope}[efidisk_attributes][storage]`,
          value: 'local',
        },
        format: {
          name: `${paramScope}[efidisk_attributes][format]`,
          value: 'raw',
        },
        pre_enrolled_keys: {
          name: `${paramScope}[efidisk_attributes][pre_enrolled_keys]`,
          value: '1',
        },
      };

      if (!isPreExisting) {
        let initialVolId = setEfiDiskVolId(null, initEfiDisk.storage.value, vmId);
        initEfiDisk.volid.value = initialVolId;
      }

      setEfiDisk(true);
      setEfiDiskData(initEfiDisk);
    },
    [efiDisk, 0, paramScope]
  );

  const removeEfiDisk = () => {
    setEfiDisk(false);
  };

  return (
    <div>
      <PageSection padding={{ default: 'noPadding' }}>
        <Button
          ouiaId="proxmox-server-storage-cdrom"
          onClick={addCDRom}
          variant="secondary"
          isDisabled={cdRom}
        >
          {' '}
          {__('Add CD-ROM')}
        </Button>
        {'  '}
        <Button
          ouiaId="proxmox-server-storage-harddisk"
          onClick={addHardDisk}
          variant="secondary"
        >
          {__('Add HardDisk')}
        </Button>
        {'  '}
        <Button
          ouiaId="proxmox-server-storage-efidisk"
          onClick={addEfiDisk}
          variant="secondary"
          isDisabled={efiDisk}
        >
          {__('Add Efi Disk')}
        </Button>
        {cdRom && cdRomData && (
          <CDRom
            onRemove={removeCDRom}
            data={cdRomData}
            storages={storages}
            nodeId={nodeId}
          />
        )}
        {efiDisk && efiDiskData && (
          <EFIDisk
            onRemove={removeEfiDisk}
            data={efiDiskData}
            storages={storages}
            nodeId={nodeId}
            vmId={vmId}
          />
        )}
        {hardDisks.map(hardDisk => (
          <div
            key={hardDisk.id}
            style={{
              position: 'relative',
              display: hardDisk.hidden ? 'none' : 'block',
            }}
          >
            <div
              style={{
                marginTop: '10px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <Title ouiaId="proxmox-server-storage-harddisk" headingLevel="h4">
                {sprintf(__('Hard Disk %(hddId)s'), { hddId: hardDisk.id })}
              </Title>
              <button onClick={() => removeHardDisk(hardDisk.id)} type="button">
                <TimesIcon />
              </button>
            </div>
            <HardDisk
              id={hardDisk.id}
              data={hardDisk.data}
              storages={hardDisk.storages}
              disks={hardDisk.disks}
              updateHardDiskData={updateHardDiskData}
              createUniqueDevice={createUniqueDevice}
              hidden={hardDisk.hidden ? true : ''}
            />
          </div>
        ))}
      </PageSection>
    </div>
  );
};

ProxmoxServerStorage.propTypes = {
  storage: PropTypes.object,
  efidisk: PropTypes.object,
  storages: PropTypes.array,
  nodeId: PropTypes.string,
  vmId: PropTypes.string,
  paramScope: PropTypes.string,
};

ProxmoxServerStorage.defaultProps = {
  storage: {},
  efidisk: {},
  storages: [],
  nodeId: '',
  vmId: '',
  paramScope: '',
};

export default ProxmoxServerStorage;
