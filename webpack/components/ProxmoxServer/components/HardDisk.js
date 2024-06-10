import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  PageSection,
} from '@patternfly/react-core';
import InputField from '../../common/FormInputs';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';

const HardDisk = ({ id, data, storages, disks, updateHardDiskData }) => {
  const [hdd, setHdd] = useState(data);
  const storagesMap = storages.map(st => ({value: st.storage, label: st.storage}));

  useEffect(() => {
    const currentHddData = JSON.stringify(hdd);
    const parentHddData = JSON.stringify(data);
    
    if (currentHddData !== parentHddData) {
      updateHardDiskData(id, hdd);
    }
  }, [hdd, id, data, updateHardDiskData]);
  const handleChange = (e) => {
    const { name, value } = e.target;
    const updatedKey = Object.keys(hdd).find(key => hdd[key].name === name);
    setHdd(prevData => ({
      ...prevData,
      [updatedKey]: { ...prevData[updatedKey], value: value },
    }));
  };
  return (
    <div >
        <Divider component="li" style={{ marginBottom: '2rem' }} />
	<input
	  name={hdd.storage_type.name}
	  type="hidden"
          value={hdd.storage_type.value}
          onChange={handleChange}
        />
	<input
	  name={hdd.device.name}
	  type="hidden"
          value={hdd.device.value}
          onChange={handleChange}
        />
	<input
	  name={hdd.id.name}
	  type="hidden"
          value={hdd.id.value}
          onChange={handleChange}
        />
        <InputField
	  name={hdd.storage.name}
          label="Storage"
          type="select"
          value={hdd.storage.value}
          options={storagesMap}
          onChange={handleChange}
        />
        <InputField
	  name={hdd.controller.name}
          label="Controller"
          type="select"
          value={hdd.controller.value}
          options={ProxmoxComputeSelectors.proxmoxControllersHDDMap}
          onChange={handleChange}
        />
        <InputField
	  name={hdd.cache.name}
          label="Cache"
          type="select"
          value={hdd.cache.value}
          options={ProxmoxComputeSelectors.proxmoxCachesMap}
          onChange={handleChange}
        />
        <InputField
	  name={hdd.size.name}
          label="Size"
          type="number"
          value={hdd.size.value}
          onChange={handleChange}
        />
    </div>
  );
};

export default HardDisk;
