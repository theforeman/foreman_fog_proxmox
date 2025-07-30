import React, { useState, useEffect } from 'react';
import {
  PageSection,
  Divider,
  Tabs,
  Tab,
  TabTitleText,
} from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import PropTypes from 'prop-types';
import { networkSelected } from './ProxmoxVmUtils';
import ProxmoxComputeSelectors from './ProxmoxComputeSelectors';
import ProxmoxServerStorage from './ProxmoxServer/ProxmoxServerStorage';
import ProxmoxServerOptions from './ProxmoxServer/ProxmoxServerOptions';
import ProxmoxServerNetwork from './ProxmoxServer/ProxmoxServerNetwork';
import ProxmoxServerHardware from './ProxmoxServer/ProxmoxServerHardware';
import ProxmoxContainerNetwork from './ProxmoxContainer/ProxmoxContainerNetwork';
import ProxmoxContainerOptions from './ProxmoxContainer/ProxmoxContainerOptions';
import ProxmoxContainerStorage from './ProxmoxContainer/ProxmoxContainerStorage';
import ProxmoxContainerHardware from './ProxmoxContainer/ProxmoxContainerHardware';
import InputField from './common/FormInputs';
import GeneralTabContent from './GeneralTabContent';

const ProxmoxVmType = ({
  vmAttrs,
  nodes,
  images,
  pools,
  fromProfile,
  newVm,
  storages,
  bridges,
  registerComp,
  untemplatable,
}) => {
  const nodesMap =
    nodes.length > 0
      ? nodes.map(node => ({ value: node.node, label: node.node }))
      : [];
  const imagesMap =
    images.length > 0
      ? [
          { value: '', label: '' },
          ...images.map(image => ({
            value: image.uuid,
            label: image.name,
          })),
        ]
      : [];
  const poolsMap =
    pools.length > 0
      ? [
          { value: '', label: '' },
          ...pools.map(pool => ({
            value: pool.poolid,
            label: pool.poolid,
          })),
        ]
      : [];
  const [activeTabKey, setActiveTabKey] = useState(0);
  const handleTabClick = (event, tabIndex) => {
    setActiveTabKey(tabIndex);
  };
  const [general, setGeneral] = useState(vmAttrs);
  const paramScope = fromProfile
    ? 'compute_attribute[vm_attrs]'
    : 'host[compute_attributes]';
  const [filteredBridges, setFilteredBridges] = useState([]);
  useEffect(() => {
    if (!registerComp && !fromProfile) {
      networkSelected(general?.type?.value);
    }
  }, [general?.type?.value]);

  useEffect(() => {
    if (!registerComp) {
      const filtered = bridges.filter(
        bridge => bridge.node_id === general?.nodeId?.value
      );
      setFilteredBridges(filtered);
    }
  }, [general?.nodeId?.value, bridges]);
  if (registerComp) {
    return null;
  }
  const componentMap = {
    qemu: {
      options: <ProxmoxServerOptions options={vmAttrs} />,
      hardware: <ProxmoxServerHardware hardware={vmAttrs} />,
      network: (
        <ProxmoxServerNetwork
          network={vmAttrs?.interfaces || {}}
          bridges={filteredBridges}
          paramScope={paramScope}
        />
      ),
      storage: (
        <ProxmoxServerStorage
          storage={vmAttrs?.disks || {}}
          storages={storages}
          nodeId={general?.nodeId?.value}
          paramScope={paramScope}
        />
      ),
    },
    lxc: {
      options: (
        <ProxmoxContainerOptions
          options={vmAttrs}
          storages={storages}
          paramScope={paramScope}
          nodeId={general?.nodeId?.value}
        />
      ),
      hardware: <ProxmoxContainerHardware hardware={vmAttrs} />,
      network: (
        <ProxmoxContainerNetwork
          network={vmAttrs?.interfaces || {}}
          bridges={filteredBridges}
          paramScope={paramScope}
        />
      ),
      storage: (
        <ProxmoxContainerStorage
          storage={vmAttrs?.disks || {}}
          storages={storages}
          nodeId={general?.nodeId?.value}
          paramScope={paramScope}
        />
      ),
    },
  };

  const handleChange = e => {
    const { name, type, checked, value: targetValue } = e.target;
    let value;
    if (type === 'checkbox') {
      value = checked ? '1' : '0';
    } else {
      value = targetValue;
    }
    const updatedKey = Object.keys(general).find(
      key => general[key].name === name
    );

    setGeneral(prevGeneral => ({
      ...prevGeneral,
      [updatedKey]: { ...prevGeneral[updatedKey], value },
    }));
  };

  return (
    <div>
      <InputField
        name={general?.type?.name}
        label={__('Type')}
        required
        onChange={handleChange}
        value={general?.type?.value}
        options={ProxmoxComputeSelectors.proxmoxTypesMap}
        disabled={!newVm}
        type="select"
      />
      <Tabs
        ouiaId="proxmox-vm-type-tabs-options"
        activeKey={activeTabKey}
        onSelect={handleTabClick}
        aria-label="Options tabs"
        role="region"
      >
        <Tab
          ouiaId="proxmox-vm-type-tab-general"
          eventKey={0}
          title={<TabTitleText>{__('General')}</TabTitleText>}
          aria-label="Default content - general"
        >
          <GeneralTabContent
            general={general}
            fromProfile={fromProfile}
            newVm={newVm}
            nodesMap={nodesMap}
            poolsMap={poolsMap}
            imagesMap={imagesMap}
            handleChange={handleChange}
            untemplatable={untemplatable}
          />
        </Tab>
        <Tab
          ouiaId="proxmox-vm-type-tab-advanced"
          eventKey={1}
          title={<TabTitleText>{__('Advanced Options')}</TabTitleText>}
          aria-label="advanced options"
        >
          <PageSection padding={{ default: 'noPadding' }}>
            <Divider component="li" style={{ marginBottom: '2rem' }} />
            {componentMap[general?.type?.value]?.options}
          </PageSection>
        </Tab>
        <Tab
          ouiaId="proxmox-vm-type-tab-hardware"
          eventKey={2}
          title={<TabTitleText>{__('Hardware')}</TabTitleText>}
          aria-label="hardware"
        >
          <PageSection padding={{ default: 'noPadding' }}>
            <Divider component="li" style={{ marginBottom: '2rem' }} />
            {componentMap[general?.type?.value]?.hardware}
          </PageSection>
        </Tab>
        {fromProfile && (
          <Tab
            ouiaId="proxmox-vm-type-tab-network"
            eventKey={3}
            title={<TabTitleText>{__('Network Interfaces')}</TabTitleText>}
            aria-label="Network interface"
          >
            <PageSection padding={{ default: 'noPadding' }}>
              <Divider component="li" style={{ marginBottom: '2rem' }} />
              {componentMap[general?.type?.value]?.network}
            </PageSection>
          </Tab>
        )}
        <Tab
          ouiaId="proxmox-vm-type-tab-storage"
          eventKey={4}
          title={<TabTitleText>{__('Storage')}</TabTitleText>}
          aria-label="storage"
        >
          <PageSection padding={{ default: 'noPadding' }}>
            <Divider component="li" style={{ marginBottom: '2rem' }} />
            {componentMap[general?.type?.value]?.storage}
          </PageSection>
        </Tab>
      </Tabs>
    </div>
  );
};

ProxmoxVmType.propTypes = {
  vmAttrs: PropTypes.object,
  nodes: PropTypes.array,
  images: PropTypes.array,
  pools: PropTypes.array,
  fromProfile: PropTypes.bool,
  newVm: PropTypes.bool,
  storages: PropTypes.array,
  bridges: PropTypes.array,
  registerComp: PropTypes.bool,
  untemplatable: PropTypes.bool,
};

ProxmoxVmType.defaultProps = {
  vmAttrs: {},
  nodes: [],
  images: [],
  pools: [],
  fromProfile: false,
  newVm: false,
  storages: [],
  bridges: [],
  registerComp: false,
  untemplatable: false,
};

export default ProxmoxVmType;
