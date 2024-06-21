import React, { useState, useEffect } from 'react';
import {
  Button,
  Title,
  Divider,
  PageSection,
  ExpandableSection,
  ExpandableSectionToggle,
  Modal,
  ModalVariant,
} from '@patternfly/react-core';
import Select from 'foremanReact/components/common/forms/Select';
import TextInput from 'foremanReact/components/common/forms/TextInput';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';
import MountPoint from './MountPoint';
import TimesIcon from '@patternfly/react-icons/dist/esm/icons/times-icon';
const ProxmoxContainerStorage = ({storage}) => {
  const handleChange = (e) => {
    onChange({
      ...storage,
      [e.target.name]: e.target.value,
    });
  };
  const [mountPoints, setMountPoints] = useState([]);
  const [nextId, setNextId] = useState(1);

  const addMountPoint = (event) => {
    if (event) event.preventDefault();
    const newMountPoint = <MountPoint key={nextId} id={nextId} />;
    setMountPoints([...mountPoints, newMountPoint]);
    setNextId(prevId => prevId + 1);
  };

  const removeMountPoint = (idToRemove) => {
    const newMountPoints = mountPoints.filter(mountPoint => mountPoint.props.id !== idToRemove);
    setMountPoints(newMountPoints);
  };
  let cputype = '';
  return (
    <div>
     <PageSection padding={{ default: 'noPadding' }}>
       <Title headingLevel="h3">Rootfs</Title>
       <Divider component="li" style={{ marginBottom: '2rem' }} />
	  <InputField
              label="Storage"
              type="select"
              value={cputype}
              options={ProxmoxComputeSelectors.proxmoxCpusMap}
              onChange={handleChange}
            />
            <InputField
              label="Path"
              value={cputype}
              onChange={handleChange}
            />
            <InputField
              label="Device"
              value={cputype}
              onChange={handleChange}
            />
            <InputField
              label="Size"
              value={cputype}
              onChange={handleChange}
            />
      </PageSection>
    <PageSection padding={{ default: 'noPadding' }}>
       <Title headingLevel="h3">Storage</Title>
       <Divider component="li" style={{ marginBottom: '2rem' }} />
       <Button onClick={addMountPoint} variant="secondary" >Add MountPoint</Button>
      {mountPoints.map(mountPoint => (
        <div key={mountPoint.props.id} style={{ position: 'relative' }}>
          <div style={{ marginTop: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Title headingLevel="h4"> Hard Disk {mountPoint.props.id} </Title>
          <button
              onClick={() => removeMountPoint(mountPoint.props.id)}
              variant="plain"
          >
            <TimesIcon/>
          </button>
          </div>
          {mountPoint}
        </div>
      ))}
      </PageSection>
    </div>
  );
};

export default ProxmoxContainerStorage;

