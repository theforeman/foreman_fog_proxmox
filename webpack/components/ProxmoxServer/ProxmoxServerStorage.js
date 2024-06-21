import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  PageSection,
  Button,
} from '@patternfly/react-core';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';
import HardDisk from './components/HardDisk';
import CloudInit from './components/CloudInit';
import CDRom from './components/CDRom';
import TimesIcon from '@patternfly/react-icons/dist/esm/icons/times-icon';

const ProxmoxServerStorage = ({storage, storages, volids}) => {
  const [hardDisks, setHardDisks] = useState([]); 
  const [nextId, setNextId] = useState(0);
  const [cloudInit, setCloudInit] = useState(false);
  const [cDRom, setCDRom] = useState(false);
  const [cdRomData, setCDRomData] = useState(null);
  const [nextDeviceNumbers, setNextDeviceNumbers] = useState({
    ide: 0,
    sata: 0,
    scsi: 0,
    virtio: 0,
  });
  const images = '';
  const controllerRanges = {
    ide: { min: 0, max: 3 },
    sata: { min: 0, max: 5 },
    scsi: { min: 0, max: 30 },
    virtio: { min: 0, max: 15 },
  };

  const initialControllerCounts = {
    ide: 0,
    sata: 0,
    scsi: 0,
    virtio: 0,
  };

  useEffect(() => {
    if (storage && storage.length > 0) {
      const updatedCounts = { ...nextDeviceNumbers };
      storage.forEach((disk) => {
        if (disk.name === 'hard_disk') {
          const controller = disk.value.controller.value;
          const device = parseInt(disk.value.device.value, 10);
          if (device >= updatedCounts[controller]) {
            updatedCounts[controller] = device + 1;
          }
	  addHardDisk(null, disk.value, true);
	}
      });
      setNextDeviceNumbers(updatedCounts);
    }
  }, [storage]);

  const getNextDevice = (controller) => {
    const currentCount = nextDeviceNumbers[controller];
    if (currentCount <= controllerRanges[controller].max) {
      const newCounts = { ...nextDeviceNumbers, [controller]: currentCount + 1 };
      setNextDeviceNumbers(newCounts);
      return currentCount;
    }
    return null; 
  };

  const createUniqueDevice = (type, selectedController = 'virtio') => {
    let controller = selectedController;
    if (type === 'cdrom') {
      controller = 'ide';
      return { controller, device: 2, id: 'ide2' };
    }

    const device = getNextDevice(controller);
    if (device !== null) {
      let id = `${controller}${device}`;

      if (controller === 'ide' && device === 2 && cDRom) {
        const nextDevice = getNextDevice(controller);
        id = `${controller}${nextDevice}`;
      }
      return { controller, device, id };
    }
    return null;
  };

  const addHardDisk = (event, initialData = null, isPreExisting = false) => {
    if (event) event.preventDefault();
    let deviceInfo = null;
    if (!isPreExisting) {
      const selectedController = initialData?.controller?.value || 'virtio';
      deviceInfo = createUniqueDevice('hard_disk', selectedController);
      if (!deviceInfo) return;
    }
    const { controller, device, id } = deviceInfo || {};
    const initHdd = initialData || {
      id: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][id]`, value: id },
      device: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][device]`, value: device },
      storage_type: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][storage_type]`, value: 'hard_disk' },
      storage: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][storage]`, value: 'local' },
      cache: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][cache]`, value: null },
      size: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][size]`, value: 8 },
      controller: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][controller]`, value: controller },
    };

    setNextId(prevNextId => {
        const newNextId = prevNextId + 1;
        const newHardDisk = {
            id: newNextId,
            storages: storages,
            data: initHdd,
            disks: storage,
        };
        setHardDisks(prevHardDisks => [...prevHardDisks, newHardDisk]);
        return newNextId;
    });
  };

  const removeHardDisk = (idToRemove) => {
    const newHardDisks = hardDisks.filter(hardDisk => hardDisk.id !== idToRemove);
    setHardDisks(newHardDisks);
  };

  const updateHardDiskData = (id, updatedData) => {
    setHardDisks(hardDisks.map(disk => disk.id === id ? { ...disk, data: updatedData } : disk));
  };

  const addCloudInit = (event) => {
      setCloudInit(true);
  };

  const removeCloudInit = () => {
    setCloudInit(false);
  };

  const addCDRom = (event, initialData = null, isPreExisting = false) => {
    if (event) event.preventDefault();
    if (cDRom) return;

    const deviceInfo = initialData ? { controller: 'ide', device: 2, id: 'ide2' } : createUniqueDevice('cdrom');
    if (!deviceInfo) return;

    const initCDRom = initialData || {
      id: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][id]`, value: deviceInfo.id },
      volid: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][volid]`, value: '' },
      storage_type: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][storage_type]`, value: 'cdrom' },
      storage: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][storage]`, value: 'local' },
      cdrom: { name: `compute_attribute[vm_attrs][volumes_attributes][${nextId}][cdrom]`, value: '' },
    };

    setCDRom(true);
    setCDRomData(initCDRom);
  };

  const removeCDRom = () => {
    setCDRom(false);
  };

  console.log("hardDisks are", hardDisks);
  return (
     <div>
      <PageSection padding={{ default: 'noPadding' }}>
        <Button onClick={addCloudInit} variant="secondary"  isDisabled={cloudInit}> Add Cloud-init </Button>
      {'  '}
        <Button onClick={addCDRom} variant="secondary" isDisabled={cDRom}> Add CD-ROM </Button>
      {'  '}
      <Button onClick={addHardDisk} variant="secondary" >Add HardDisk</Button>
      {cloudInit && (
        <CloudInit onRemove={removeCloudInit} />
      )}
      {cDRom && cdRomData && (
        <CDRom onRemove={removeCDRom} data={cdRomData} storages={storages} volids={volids} />
      )}
      {hardDisks.map((hardDisk) => (
        <div style={{ position: 'relative' }}>
	  <div style={{ marginTop: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Title headingLevel="h4"> Hard Disk {hardDisk.id} </Title>
	  <button
              onClick={() => removeHardDisk(hardDisk.id)}
              variant="plain"
	      type="button"
	  >
            <TimesIcon/>
          </button>
          </div>
	  <HardDisk
              id={hardDisk.id}
              data={hardDisk.data}
              storages={hardDisk.storages}
	      disks={hardDisk.disks}
	      updateHardDiskData={updateHardDiskData}
	      createUniqueDevice={createUniqueDevice}
            />
        </div>
      ))}
      </PageSection>
    </div>
  );
};

export default ProxmoxServerStorage;

