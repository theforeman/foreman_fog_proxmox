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

  useEffect(() => {  
    addHardDisk();
  }, []);

  const addHardDisk = (event) => {
    if (event) event.preventDefault();
    const newHardDisk = <HardDisk key={nextId} id={nextId} storage={storage} storages={storages}/>;
    setHardDisks([...hardDisks, newHardDisk]);
    setNextId(prevId => prevId + 1);
  };

  const removeHardDisk = (idToRemove) => {
    const newHardDisks = hardDisks.filter(hardDisk => hardDisk.props.id !== idToRemove);
    setHardDisks(newHardDisks);
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
      {hardDisks.map(hardDisk => (
        <div key={hardDisk.props.id} style={{ position: 'relative' }}>
	  <div style={{ marginTop: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Title headingLevel="h4"> Hard Disk {hardDisk.props.id} </Title>
	  <button
              onClick={() => removeHardDisk(hardDisk.props.id)}
              variant="plain"
	  >
            <TimesIcon/>
          </button>
          </div>
          {hardDisk}
        </div>
      ))}
      </PageSection>
    </div>
  );
};

export default ProxmoxServerStorage;

