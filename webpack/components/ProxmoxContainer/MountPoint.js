import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  PageSection,
} from '@patternfly/react-core';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';

const MountPoint = ({ id }) => {
  const [hdStorage, setHdStorage] = useState('');
  const handleHdStorage = (hdStorage, event) => {
    setHdStorage(hdStorage);
  };
 
  console.log("hdd key", {id});

  return (
    <div >
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          label="Storage"
          type="select"
          options={ProxmoxComputeSelectors.proxmoxOperatingSystemsMap}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Path"
          type="select"
          options={ProxmoxComputeSelectors.proxmoxControllersCloudinitMap}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Size"
          type="number"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
	<Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          label="Storage Type"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Device"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="ID"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
    </div>
  );
};

export default MountPoint;
