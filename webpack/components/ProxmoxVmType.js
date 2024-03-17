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
import ProxmoxContainerNetwork from './ProxmoxContainer';
import ProxmoxContainerOptions from './ProxmoxContainer';
import ProxmoxContainerStorage from './ProxmoxContainer';
import InputField from './common/FormInputs';
import { connect } from 'react-redux';
import {
  setVmId,
  setNode,
  setImage,
  setPool,
  setVmType,
} from './ProxmoxVmTypeActions';

import {
  selectVmId,
  selectNode,
  selectImage,
  selectPool,
  selectVmType,
} from './ProxmoxVmTypeSelectors';

const ProxmoxVmType = ({ 
  vm_attributes,
  paramsScope,
  vmType,
  setVmType,
  vmId,
  node,
  image,
  pool,
  nodes,
  images,
  pools,
  setVmId,
  setNode,
  setImage,
  setPool,
 from_profile, new_vm }) => {
  const nodesMap = nodes.map(node => ({value: node.node, label: node.node}));
  const imagesMap = images.map(image => ({value: image, label: image}));
  const poolsMap = pools.map(pool => ({value: pool.poolid, label: pool.poolid}));
  const [activeTabKey, setActiveTabKey] = React.useState(0);
  const handleTabClick = (event, tabIndex) => {
    setActiveTabKey(tabIndex);
  };
/*
  const renderSelectedForm = () => {
    console.log("*********************8 vmType is ", vmType);
    switch (vmType) {
      case 'qemu':
        return <ProxmoxServer />;
      case 'lxc':
        return <ProxmoxContainer />;
      default:
        return null;
    }
  }; */
  console.log("*****************8 paramsScope  ", paramsScope, "vm_attras", vm_attributes);
  const proxmoxTypesMap = [
    { value: 'qemu', label: 'KVM/Qemu server' },
    { value: 'lxc', label: 'LXC container' },
  ];
  return (
    <div>
      <InputField
        label="Type"
        required
        onChange={e => setVmType(e.target.value)}
        value={vmType}
        options={ProxmoxComputeSelectors.proxmoxTypesMap}
        type="select"
      />
      <Tabs activeKey={activeTabKey} onSelect={handleTabClick} aria-label="Tabs in the default example" role="region">
      <Tab eventKey={0} title={<TabTitleText>General</TabTitleText>} aria-label="Default content - general">
      <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          label="VM ID"
          required
          value={vmId}
          onChange={e => setVmId(e.target.value)}
        />
        <InputField
          label="Node"
          required
          type="select"
          value={node}
          options={nodesMap}
          onChange={e => setNode(e.target.value)}
        />
        <InputField
          label="Image"
          type="select"
          value={image}
          options={imagesMap}
          onChange={e => setImage(e.target.value)}
        />
        <InputField
          label="Pool"
          type="select"
          value={pool}
          options={poolsMap}
          onChange={e => setPool(e.target.value)}
        />
      </PageSection>
      </Tab>
      <Tab eventKey={1} title={<TabTitleText>Advanced Options</TabTitleText>} aria-label="advanced options">
	  {(vmType === 'qemu') ? (<ProxmoxServerOptions />) : null}
	  {(vmType === 'lxc') ? (<ProxmoxContainerOptions />) : null }
      </Tab>
      <Tab eventKey={2} title={<TabTitleText>Network Interfaces</TabTitleText>} aria-label="Network interface">
	  {(vmType === 'qemu') ? (<ProxmoxServerNetwork />) : (<ProxmoxContainerNetwork />)}
      </Tab>
      <Tab eventKey={3} title={<TabTitleText>Storage</TabTitleText>} aria-label="storage">
	  {(vmType === 'qemu') ? (<ProxmoxServerStorage />) : (<ProxmoxContainerStorage />)}
      </Tab>
      </Tabs>
      <div className="compute-attribute-body">
          <input
            value={vmType}
            id="controller_hidden"
            name={paramsScope}
            type="hidden"
          />
      </div>
    </div>
  );
};

const mapStateToProps = (state) => ({
  vmType: selectVmType(state),
  vmId: selectVmId(state),
  node: selectNode(state),
  image: selectImage(state),
  pool: selectPool(state),
  state: state // Pass the entire state as a prop
});

const mapDispatchToProps = {
  setVmType,
  setVmId,
  setNode,
  setImage,
  setPool,
};

export default connect(mapStateToProps, mapDispatchToProps)(ProxmoxVmType);
