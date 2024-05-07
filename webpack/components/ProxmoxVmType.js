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
import ProxmoxContainerNetwork from './ProxmoxContainer';
import ProxmoxContainerOptions from './ProxmoxContainer';
import ProxmoxContainerStorage from './ProxmoxContainer';
import InputField from './common/FormInputs';
import { connect } from 'react-redux';

const ProxmoxVmType = ({ 
  vm_attributes,
  paramsScope,
  nodes,
  images,
  pools,
 from_profile, new_vm }) => {
  const nodesMap = nodes.map(node => ({value: node.node, label: node.node}));
  const imagesMap = images.map(image => ({value: image, label: image}));
  const poolsMap = pools.map(pool => ({value: pool.poolid, label: pool.poolid}));
  const [activeTabKey, setActiveTabKey] = React.useState(0);
  const handleTabClick = (event, tabIndex) => {
    setActiveTabKey(tabIndex);
  };
  const [vmAttributes, setVmAttributes] = useState(vm_attributes);
  const [general, setGeneral] = useState(vm_attributes.general);
  const image = '';

  const handleOptionsChange = (newOptionsValues) => {
    console.log("****************8 vm attrs", vmAttributes);
    setVmAttributes({
      ...vmAttributes,
      options: newOptionsValues,
    });
  };

  const componentMap = {
    'qemu': {
      options: <ProxmoxServerOptions options={vmAttributes.options} onOptionsChange={handleOptionsChange}/>,
      hardware: <ProxmoxServerHardware />,
      network: <ProxmoxServerNetwork />,
      storage: <ProxmoxServerStorage />,
    },
    'lxc': {
      options: <ProxmoxContainerOptions />,
      network: <ProxmoxContainerNetwork />,
      storage: <ProxmoxContainerStorage />
    },
  };

  const handleChange = (e) => { 
    setGeneral({
      ...general,
      [e.target.name]: e.target.value,
    });
  };

  console.log("*************** vm_attributes", vm_attributes);
  return (
    <div>
      <InputField
	name='type'
        label="Type"
        required
        onChange={e => handlechange(e)}
        value={general.type}
        options={ProxmoxComputeSelectors.proxmoxTypesMap}
        type="select"
      />
      <Tabs activeKey={activeTabKey} onSelect={handleTabClick} aria-label="Tabs in the default example" role="region">
      <Tab eventKey={0} title={<TabTitleText>General</TabTitleText>} aria-label="Default content - general">
      <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
	  name='vmid'
          label="VM ID"
          required
          value={general.vmid}
          onChange={handleChange}
        />
        <InputField
	  name='node'
          label="Node"
          required
          type="select"
          value={general.node_id}
          options={nodesMap}
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
	  name='pool'
          label="Pool"
          type="select"
          value={general.pool}
          options={poolsMap}
          onChange={handleChange}
        />
	<InputField
	  name='description'
              label="Description"
              type="textarea"
              value={general.description}
              onChange={handleChange}
            />
	
      </PageSection>
      </Tab>
      <Tab eventKey={1} title={<TabTitleText>Advanced Options</TabTitleText>} aria-label="advanced options">
        <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
	  {componentMap[general.type]?.options}
	</PageSection>
      </Tab>
      <Tab eventKey={2} title={<TabTitleText>Hardware</TabTitleText>} aria-label="hardware">
        <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
	  {componentMap[general.type]?.hardware}
        </PageSection>
      </Tab>
      <Tab eventKey={3} title={<TabTitleText>Network Interfaces</TabTitleText>} aria-label="Network interface">
        <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
          {componentMap[general.type]?.network}
        </PageSection>
      </Tab>
      <Tab eventKey={4} title={<TabTitleText>Storage</TabTitleText>} aria-label="storage">
        <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
          {componentMap[general.type]?.storage}
        </PageSection>
      </Tab>
      </Tabs>
      <div className="compute-attribute-body">
	  <input
	  value={{'type': general.type}}
            id="controller_hidden"
            name={paramsScope}
            type="hidden"
          />
      </div>
    </div>
  );
};


export default ProxmoxVmType;
