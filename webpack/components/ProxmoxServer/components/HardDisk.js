import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  PageSection,
} from '@patternfly/react-core';
import InputField from '../../common/FormInputs';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';

const HardDisk = ({ key, onRemove }) => {
  const [hdStorage, setHdStorage] = useState('');
  const handleHdStorage = (hdStorage, event) => {
    setHdStorage(hdStorage);
  };

  return (
    <div style={{ position: 'relative' }} >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
	<button
          style={{ position: 'absolute', top: '5px', right: '5px', cursor: 'pointer', backgroundColor: 'red', border: 'none' }}
          onClick={onRemove}
        >
          X
        </button>
        <Title headingLevel="h4"> Hard Disk </Title>
      </div>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          label="Storage"
          type="select"
          options={ProxmoxComputeSelectors.proxmoxOperatingSystemsMap}
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
