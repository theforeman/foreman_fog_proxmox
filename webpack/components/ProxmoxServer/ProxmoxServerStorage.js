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
import TimesIcon from '@patternfly/react-icons/dist/esm/icons/times-icon';

const ProxmoxServerStorage = ({storage, storages}) => {
  const [hardDisks, setHardDisks] = useState([]); 
  const [nextId, setNextId] = useState(0);

  const getNextAvailableDeviceNumber = (controller, storage) => {
    const controllerRanges = {
      ide: { min: 0, max: 3 },
      sata: { min: 0, max: 5 },
      scsi: { min: 0, max: 30 },
      virtio: { min: 0, max: 15 }
    };
    const devicesWithSameController = storage.filter(device => device.value.controller.value === controller);
    const existingDeviceNumbers = devicesWithSameController.map(device => device.value.device.value);
    const { min, max } = controllerRanges[controller];

    let nextDeviceNumber = min;
    while (existingDeviceNumbers.includes(nextDeviceNumber)) {
      nextDeviceNumber++;
      if (nextDeviceNumber > max) {
        nextDeviceNumber = min;
      }
    }
    return nextDeviceNumber;
  };

  useEffect(() => {
    if (storage && storage.length > 0) {
      storage.forEach((disk, index) => {
	if (disk.name === 'hard_disk') {
          addHardDisk(null, disk.value);
	}
      });
    }
  }, [storage]);
  const device = '0';   
  const initHdd = {
    id: {name: 'compute_attribute[vm_attrs][volumes_attributes][' + (storage.length + 1) + '][id]', value: ('virtio' + device)},
    device: {name: 'compute_attribute[vm_attrs][volumes_attributes][' + (storage.length + 1) + '][device]', value: device},
    storage_type: {name: 'compute_attribute[vm_attrs][volumes_attributes][' + (storage.length + 1) + '][storage_type]', value: 'hard_disk'},
    storage: {name: 'compute_attribute[vm_attrs][volumes_attributes][' + (storage.length + 1) + '][storage]', value: 'local'},
    cache: {name: 'compute_attribute[vm_attrs][volumes_attributes][' + (storage.length + 1) + '][cache]', value: null},
    size: {name: 'compute_attribute[vm_attrs][volumes_attributes][' + (storage.length + 1) + '][size]', value: 8},
    controller: {name: 'compute_attribute[vm_attrs][volumes_attributes][' + (storage.length + 1) + '][controller]', value: 'virtio'},
  };
  const addHardDisk = (event, initialData = initHdd) => {
    if (event) event.preventDefault();
    const newHardDisk = {
      id: nextId,
      storages: storages,
      data: initialData,
      disks: storage,
    };
    setHardDisks(prevHardDisks => [...prevHardDisks, newHardDisk]);
    setNextId(prevId => prevId + 1);
  };

  const removeHardDisk = (event, idToRemove) => {
    if (event) event.preventDefault();
    const newHardDisks = hardDisks.filter(hardDisk => hardDisk.props.id !== idToRemove);
    setHardDisks(newHardDisks);
  };

  const updateHardDiskData = (id, updatedData) => {
    setHardDisks(hardDisks.map(disk => disk.id === id ? { ...disk, data: updatedData } : disk));
  };

  const [cloudInit, setCloudInit] = useState(false);

  const addCloudInit = (event) => {
      setCloudInit(true);
  };

  const removeCloudInit = () => {
    setCloudInit(false);
  };

  const [cdRom, setCdRom] = useState(false);
  const addCdRom = (event) => {
      setCdRom(true);
  };

  const removeCdRom = () => {
    setCdRom(false);
  };

  return (
     <div>
      <PageSection padding={{ default: 'noPadding' }}>
        <Button onClick={addCloudInit} variant="secondary"  isDisabled={cloudInit}> Add Cloud-init </Button>
      {'  '}
        <Button onClick={addCdRom} variant="secondary" isDisabled={cdRom}> Add CD-ROM </Button>
      {'  '}
      <Button onClick={addHardDisk} variant="secondary" >Add HardDisk</Button>
      {cloudInit && (
        <CloudInit onRemove={removeCloudInit} />
      )}
      {cdRom && (
        <CloudInit onRemove={removeCdRom} />
      )}
      {hardDisks.map((hardDisk) => (
        <div style={{ position: 'relative' }}>
	  <div style={{ marginTop: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Title headingLevel="h4"> Hard Disk {hardDisk.id} </Title>
	  <button
              onClick={() => removeHardDisk(hardDisk.id)}
              variant="plain"
	  >
            <TimesIcon/>
          </button>
          </div>
	  <HardDisk
              id={hardDisk.id}
              data={hardDisk.data}
              storages={hardDisk.storages}
	      disks={hardDisk.disks}
	      getNextAvailableDeviceNumber={getNextAvailableDeviceNumber}
	      updateHardDiskData={updateHardDiskData}
            />
        </div>
      ))}
      </PageSection>
    </div>
  );
};

export default ProxmoxServerStorage;

