import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Button,
  Title,
  Divider,
  PageSection,
} from '@patternfly/react-core';
import InputField from '../../common/FormInputs';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';
import TimesIcon from '@patternfly/react-icons/dist/esm/icons/times-icon';

const CloudInit = ({ onRemove }) => {
  const [hdStorage, setHdStorage] = useState('');
  const handleHdStorage = (hdStorage, event) => {
    setHdStorage(hdStorage);
  };

  return (
    <div style={{ position: 'relative' }} >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Title headingLevel="h4">Cloud-init  </Title>
        <button onClick={onRemove} ><TimesIcon/></button>
      </div>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          label="Storage"
          type="text"
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
    </div>
  );
};

export default CloudInit;
