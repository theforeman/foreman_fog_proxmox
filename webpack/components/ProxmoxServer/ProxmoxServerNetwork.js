import React, { useState, useEffect } from 'react';
import NetworkInterface from './components/NetworkInterface';
import {
  Title,
  Divider,
  PageSection,
  Button,
} from '@patternfly/react-core';
import TimesIcon from '@patternfly/react-icons/dist/esm/icons/times-icon';
const ProxmoxServerNetwork = () => {

  const [interfaces, setInterfaces] = useState([]);
  const [nextId, setNextId] = useState(1);

  useEffect(() => {
    addInterface();
  }, []);

  const addInterface = (event) => {
    if (event) event.preventDefault();
    const newInterface = <NetworkInterface key={nextId} id={nextId} />;
    setInterfaces([...interfaces, newInterface]);
    setNextId(prevId => prevId + 1);
  };

  const removeInterface = (indexToRemove) => {
    const newInterfaces = interfaces.filter(nic => nic.props.id !== indexToRemove);
    setInterfaces(newInterfaces);
  };

  return (
    <div>
      <PageSection padding={{ default: 'noPadding' }}>
	<Button onClick={addInterface} variant="secondary" >Add Interface</Button>
        {interfaces.map(nic => (
        <div key={nic.props.id} style={{ position: 'relative' }}>
          <div style={{ marginTop: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Title headingLevel="h4"> Nic {nic.props.id} </Title>
          <button
              onClick={() => removeInterface(nic.props.id)}
              variant="plain"
          >
            <TimesIcon/>
          </button>
          </div>
          {nic}
        </div>
      ))}
      </PageSection>
    </div>
  );
};

export default ProxmoxServerNetwork;
