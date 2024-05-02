import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  PageSection,
} from '@patternfly/react-core';
import InputField from '../../common/FormInputs';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';

const NetworkInterface = ({ id }) => {
  const [hdStorage, setHdStorage] = useState('');
  const handleHdStorage = (hdStorage, event) => {
    setHdStorage(hdStorage);
  };

  return (
    <div style={{ position: 'relative' }} >
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          label="Indentifier"
          type="text"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Card"
          type="select"
          options={ProxmoxComputeSelectors.proxmoxOperatingSystemsMap}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Bridge"
          type="select"
          options={ProxmoxComputeSelectors.proxmoxOperatingSystemsMap}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="VLAN Tag"
          type="text"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Rate limit"
          type="text"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Multiqueue"
          type="text"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Firewall"
          type="checkbox"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Disconnect"
          type="checkbox"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
    </div>
  );
};

export default NetworkInterface;
