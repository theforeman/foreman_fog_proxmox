/* eslint-disable max-lines */
import React, { useState, useEffect, useCallback, useRef } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  PageSection,
  Button,
  Label,
  Spinner,
  Bullseye,
  Divider,
  FormHelperText,
  HelperText,
  HelperTextItem,
} from '@patternfly/react-core';
import { TimesIcon } from '@patternfly/react-icons';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import HardDisk from './components/HardDisk';
import CDRom from './components/CDRom';
import EFIDisk from './components/EFIDisk';

const ProxmoxServerStorage = ({
  storage,
  efidisk,
  storages,
  fromProfile,
  nodeId,
  vmId,
  bootOrder,
  paramScope,
  isLoading,
  computeResourceId,
  isTabActive,
  selectedImage,
  provisionMethodState,
}) => {
  const bootDiskId = React.useMemo(() => {
    if (!bootOrder) return null;
    const match = bootOrder.match(/order=([^;][\w;]*)/);
    if (!match) return null;
    const entries = match[1]
      .split(';')
      .map(s => s.trim())
      .filter(Boolean);
    return entries.find(entry => !entry.startsWith('net')) || null;
  }, [bootOrder]);

  const templateDiskSlots = React.useMemo(() => {
    const slots = new Set();
    if (provisionMethodState !== 'image') return slots;
    const disks = selectedImage?.disks;
    if (!Array.isArray(disks)) return slots;
    disks.forEach(diskEntry => {
      if (diskEntry.includes('media=cdrom')) return;
      const match = diskEntry.match(/^([a-z]+)(\d+):/i);
      if (!match) return;
      const [, rawController, deviceStr] = match;
      const controller = rawController.toLowerCase();
      const device = parseInt(deviceStr, 10);
      if (Number.isNaN(device)) return;
      slots.add(`${controller}${device}`);
    });

    return slots;
  }, [provisionMethodState, selectedImage]);

  const templateDiskSlotList = Array.from(templateDiskSlots).sort();

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

  const initializedRef = useRef(false);

  const controllerRanges = {
    ide: { min: 0, max: 3 },
    sata: { min: 0, max: 5 },
    scsi: { min: 0, max: 30 },
    virtio: { min: 0, max: 15 },
  };

  useEffect(() => {
    if (initializedRef.current) return;

    if (Array.isArray(storage) && storage.length > 0) {
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

    initializedRef.current = true;
  }, [storage, efidisk, addHardDisk, addCDRom, addEfiDisk]); // eslint-disable-line react-hooks/exhaustive-deps
  // This is necessary because of nextDeviceNumbers. Adding nextDeviceNumbers results in infinite loop in browser.

  const getNextDevice = useCallback(
    (controller, type = null) => {
      const isDevice2Reserved = controller === 'ide' && type !== 'cdrom';
      for (
        let i = controllerRanges[controller].min;
        i <= controllerRanges[controller].max;
        i++
      ) {
        if (!(isDevice2Reserved && i === 2)) {
          const slotId = `${controller}${i}`;
          if (
            !templateDiskSlots.has(slotId) &&
            !hardDisks.some(
              disk =>
                disk.data.controller.value === controller &&
                parseInt(disk.data.device.value, 10) === i
            )
          ) {
            return i;
          }
        }
      }
      return null;
    },
    [hardDisks, controllerRanges, templateDiskSlots]
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
        setNextDeviceNumbers(prev => ({
          ...prev,
          [controller]: prev[controller] + 1,
        }));
        return { controller, device, id };
      }
      return null;
    },
    [getNextDevice]
  );

  const validateHardDiskDevice = useCallback(
    (controller, device, currentDiskId) => {
      const range = controllerRanges[controller];
      if (!range) {
        return __('Invalid device value.');
      }

      if (!/^\d+$/.test(String(device))) {
        return __('Invalid device value.');
      }

      const parsedDevice = parseInt(device, 10);

      if (parsedDevice < range.min || parsedDevice > range.max) {
        return sprintf(
          __('Device must be between %(min)s and %(max)s for %(controller)s.'),
          { min: range.min, max: range.max, controller }
        );
      }

      if (controller === 'ide' && parsedDevice === 2) {
        return __('Device ide2 is reserved for CD-ROM.');
      }

      if (templateDiskSlots.has(`${controller}${parsedDevice}`)) {
        return __('This device is reserved by the selected image template.');
      }

      if (
        hardDisks.some(
          disk =>
            disk.id !== currentDiskId &&
            !disk.hidden &&
            disk.data.controller.value === controller &&
            parseInt(disk.data.device.value, 10) === parsedDevice
        )
      ) {
        return __('This device is already in use.');
      }

      return null;
    },
    [controllerRanges, hardDisks, templateDiskSlots]
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
          value: '',
        },
        cache: {
          name: `${paramScope}[volumes_attributes][${nextId}][cache]`,
          value: null,
        },
        backup: {
          name: `${paramScope}[volumes_attributes][${nextId}][backup]`,
          value: 1,
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
          data: initHdd,
          disks: storage,
          isNew: !isPreExisting,
        };
        setHardDisks(prevHardDisks => [...prevHardDisks, newHardDisk]);
        return newNextId;
      });
    },
    [nextId, paramScope, storage, createUniqueDevice]
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
          value: '',
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

  const removeCDRom = () => setCdRom(false);

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
          value: '',
        },
        format: {
          name: `${paramScope}[efidisk_attributes][format]`,
          value: 'raw',
        },
        preEnrolledKeys: {
          name: `${paramScope}[efidisk_attributes][pre_enrolled_keys]`,
          value: '1',
        },
      };

      // Handle pre_enrolled_keys naming difference
      if (initEfiDisk.hasOwnProperty('pre_enrolled_keys')) {
        initEfiDisk.preEnrolledKeys = initEfiDisk.pre_enrolled_keys;
        /* remove old key to avoid confusion */
        delete initEfiDisk.pre_enrolled_keys;
      }

      setEfiDisk(true);
      setEfiDiskData(initEfiDisk);
    },
    [efiDisk, paramScope]
  );

  const removeEfiDisk = () => {
    setEfiDisk(false);
  };

  if (isLoading) {
    return (
      <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '1rem' }} />
        <Bullseye>
          <Spinner size="lg" />
        </Bullseye>
      </PageSection>
    );
  }

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
        {templateDiskSlotList.length > 0 && (
          <FormHelperText>
            <HelperText id="helper-template-reserved-slots">
              <HelperTextItem
                variant="warning"
                style={{ fontSize: '1rem', fontWeight: 350, lineHeight: 1.5 }}
              >
                {`${
                  templateDiskSlotList.length === 1
                    ? __('Image template reserved slot')
                    : __('Image template reserved slots')
                }: ${templateDiskSlotList.join(', ')}`}
              </HelperTextItem>
            </HelperText>
          </FormHelperText>
        )}
        {cdRom && cdRomData && (
          <CDRom
            onRemove={removeCDRom}
            data={cdRomData}
            storages={storages}
            nodeId={nodeId}
            computeResourceId={computeResourceId}
            isTabActive={isTabActive}
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
        {hardDisks.map(hardDisk => {
          const diskId = hardDisk.data?.id?.value;
          const isPersistedDisk = !!hardDisk.data?.volid?.value;
          const isBootDisk =
            isPersistedDisk && !!diskId && diskId === bootDiskId;
          return (
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
                <div
                  style={{ display: 'flex', alignItems: 'center', gap: '8px' }}
                >
                  <Title
                    ouiaId="proxmox-server-storage-harddisk"
                    headingLevel="h4"
                  >
                    {sprintf(__('Hard Disk %(hddId)s'), { hddId: hardDisk.id })}
                  </Title>
                  {isBootDisk && (
                    <Label color="blue" isCompact>
                      {__('Boot Disk')}
                    </Label>
                  )}
                </div>
                <button
                  onClick={() => removeHardDisk(hardDisk.id)}
                  type="button"
                  disabled={isBootDisk}
                  title={
                    isBootDisk ? __('Boot disk cannot be removed.') : undefined
                  }
                  style={
                    isBootDisk
                      ? { opacity: 0.4, cursor: 'not-allowed' }
                      : undefined
                  }
                >
                  <TimesIcon />
                </button>
              </div>

              <HardDisk
                id={hardDisk.id}
                data={hardDisk.data}
                storages={storages}
                fromProfile={fromProfile}
                updateHardDiskData={updateHardDiskData}
                createUniqueDevice={createUniqueDevice}
                validateDevice={validateHardDiskDevice}
                hidden={!!hardDisk.hidden}
                isNew={!!hardDisk.isNew}
                isPersistedDisk={isPersistedDisk}
              />
            </div>
          );
        })}
      </PageSection>
    </div>
  );
};

ProxmoxServerStorage.propTypes = {
  storage: PropTypes.array,
  efidisk: PropTypes.array,
  storages: PropTypes.array,
  fromProfile: PropTypes.bool,
  nodeId: PropTypes.string,
  vmId: PropTypes.string,
  bootOrder: PropTypes.string,
  paramScope: PropTypes.string,
  isLoading: PropTypes.bool,
  computeResourceId: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  isTabActive: PropTypes.bool,
  selectedImage: PropTypes.object,
  provisionMethodState: PropTypes.string,
};

ProxmoxServerStorage.defaultProps = {
  storage: [],
  efidisk: [],
  storages: [],
  fromProfile: false,
  nodeId: '',
  vmId: '',
  bootOrder: '',
  paramScope: '',
  isLoading: false,
  computeResourceId: null,
  isTabActive: false,
  selectedImage: null,
  provisionMethodState: '',
};

export default ProxmoxServerStorage;
