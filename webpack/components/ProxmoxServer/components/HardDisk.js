import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  PageSection,
} from '@patternfly/react-core';
import InputField from '../../common/FormInputs';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';

const HardDisk = ({ id, storage, storages }) => {
  const [hdStorage, setHdStorage] = useState('');
  const storagesMap = storages.map(st => ({value: st.storage, label: st.storage}));
  const handleHdStorage = (hdStorage, event) => {
    setHdStorage(hdStorage);
  };
 
  console.log("hdd key", {id}, storage);

  return (
    <div >
        <Divider component="li" style={{ marginBottom: '2rem' }} />
	<input
	  type="hidden"
	  name={`compute_attribute[vm_attrs][interfaces_attributes][${id}][storage_type]`}
          value="hard_disk"
          onChange={e => setHdStorage(e.target.value)}
        />
	<input
	  type="hidden"
	  name={`compute_attribute[vm_attrs][interfaces_attributes][${id}][device]`}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
	<input
	  type="hidden"
	  name={`compute_attribute[vm_attrs][interfaces_attributes][${id}][id]`}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Storage"
          type="select"
          options={storagesMap}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Controller"
          type="select"
          options={ProxmoxComputeSelectors.proxmoxControllersCloudinitMap}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Cache"
          type="select"
          options={ProxmoxComputeSelectors.proxmoxCachesMap}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Size"
          type="number"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
    </div>
  );
};

export default HardDisk;
