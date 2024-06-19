import React, { useState, useEffect } from 'react';
import {
  FormGroup,
  TextContent,
  Text,
  PageSection,
  Title,
  Divider,
  SelectOption,
  ExpandableSection,
  ExpandableSectionToggle,
} from '@patternfly/react-core';
import ProxmoxComputeSelectors from './ProxmoxComputeSelectors';
import {Tabs, Tab, TabTitleText, Tooltip} from '@patternfly/react-core';
import ProxmoxServerStorage from './ProxmoxServer/ProxmoxServerStorage';
import ProxmoxServerOptions from './ProxmoxServer/ProxmoxServerOptions';
import ProxmoxServerNetwork from './ProxmoxServer/ProxmoxServerNetwork';
import ProxmoxServerHardware from './ProxmoxServer/ProxmoxServerHardware';
import ProxmoxContainerNetwork from './ProxmoxContainer/ProxmoxContainerNetwork';
import ProxmoxContainerOptions from './ProxmoxContainer/ProxmoxContainerOptions';
import ProxmoxContainerStorage from './ProxmoxContainer/ProxmoxContainerStorage';
import ProxmoxContainerHardware from './ProxmoxContainer/ProxmoxContainerHardware';
import InputField from './common/FormInputs';
import { connect } from 'react-redux';

const ProxmoxVmType = ({ 
  vm_attributes,
  nodes,
  images,
  pools,
 from_profile, new_vm, storages, bridges }) => {
  console.log("*************** vm_attrs", vm_attributes);
  const nodesMap = nodes.map(node => ({value: node.node, label: node.node}));
  const imagesMap = images.map(image => ({value: image, label: image}));
  const poolsMap = pools.map(pool => ({value: pool.poolid, label: pool.poolid}));
  const [activeTabKey, setActiveTabKey] = React.useState(0);
  const handleTabClick = (event, tabIndex) => {
    setActiveTabKey(tabIndex);
  };
  const [vmAttributes, setVmAttributes] = useState(vm_attributes);
  const [general, setGeneral] = useState(vm_attributes);
  const image = '';

  const handleAttributeChange = (key, newValues) => {
    setVmAttributes({
      ...vmAttributes,
      [key]: newValues,
    });
  };

  const componentMap = {
    'qemu': {
      options: <ProxmoxServerOptions options={vm_attributes} />,
      hardware: <ProxmoxServerHardware hardware={vm_attributes} />,
      network: <ProxmoxServerNetwork network={vm_attributes.interfaces} bridges={bridges} />,
      storage: <ProxmoxServerStorage storage={vm_attributes.disks} storages={storages}/>,
    },
    'lxc': {
      options: <ProxmoxContainerOptions options={vm_attributes} />,
      hardware: <ProxmoxContainerHardware hardware={vm_attributes}  />,
      network: <ProxmoxContainerNetwork network={vm_attributes.interfaces} bridges={bridges} />,
      storage: <ProxmoxContainerStorage storage={vm_attributes.disks} />
    },
  };

  const handleChange = (e) => { 
    const { name, value } = e.target;
    const updatedKey = Object.keys(general).find(key => general[key].name === name);

    setGeneral(prevGeneral => ({
      ...prevGeneral,
      [updatedKey]: { ...prevGeneral[updatedKey], value: value },
    }));
  };

  return (
    <div>
      <InputField
	name={general.type.name}
        label="Type"
        required
        onChange={e => handleChange(e)}
        value={general.type.value}
        options={ProxmoxComputeSelectors.proxmoxTypesMap}
        type="select"
      />
      <Tabs activeKey={activeTabKey} onSelect={handleTabClick} aria-label="Tabs in the default example" role="region">
      <Tab eventKey={0} title={<TabTitleText>General</TabTitleText>} aria-label="Default content - general">
      <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
	  name={general.vmid.name}
          label="VM ID"
          required
          value={general.vmid.value}
          onChange={handleChange}
        />
        <InputField
	  name={general.node_id.name}
          label="Node"
          required
          type="select"
          value={general.node_id.value}
          options={nodesMap}
          onChange={handleChange}
        />
	<InputField
	  name={general.pool.name}
          label="Pool"
          type="select"
          value={general.pool.value}
          options={poolsMap}
          onChange={handleChange}
	/>
        <InputField
	  name='image'
          label="Image"
          type="select"
          value={image}
          options={imagesMap}
          onChange={handleChange}
        />
	<InputField
	  name='description'
	  name={general.description.name}
              label="Description"
              type="textarea"
              value={general.description.value}
              onChange={handleChange}
            />
	
      </PageSection>
      </Tab>
      <Tab eventKey={1} title={<TabTitleText>Advanced Options</TabTitleText>} aria-label="advanced options">
        <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
	  {componentMap[general.type.value]?.options}
	</PageSection>
      </Tab>
      <Tab eventKey={2} title={<TabTitleText>Hardware</TabTitleText>} aria-label="hardware">
        <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
	  {componentMap[general.type.value]?.hardware}
        </PageSection>
      </Tab>
      <Tab eventKey={3} title={<TabTitleText>Network Interfaces</TabTitleText>} aria-label="Network interface">
        <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
          {componentMap[general.type.value]?.network}
        </PageSection>
      </Tab>
      <Tab eventKey={4} title={<TabTitleText>Storage</TabTitleText>} aria-label="storage">
        <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
          {componentMap[general.type.value]?.storage}
        </PageSection>
      </Tab>
      </Tabs>
    </div>
  );
};


export default ProxmoxVmType;
