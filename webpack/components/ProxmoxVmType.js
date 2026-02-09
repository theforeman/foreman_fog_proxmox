/* eslint-disable max-lines */
import React, { useState, useEffect } from 'react';
import {
  PageSection,
  Divider,
  Tabs,
  Tab,
  TabTitleText,
  Spinner,
  Bullseye,
} from '@patternfly/react-core';
import PropTypes from 'prop-types';
import { translate as __ } from 'foremanReact/common/I18n';
import { API } from 'foremanReact/redux/API';
import { ProxmoxBiosProvider } from './ProxmoxBiosContext';

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
  images,
  fromProfile,
  newVm,
  registerComp,
  untemplatable,
  computeResourceId,
  propsLoaded,
}) => {
  const [activeTabKey, setActiveTabKey] = useState(0);
  const handleTabClick = (event, tabIndex) => setActiveTabKey(tabIndex);

  const [general, setGeneral] = useState(vmAttrs);

  const paramScope = fromProfile
    ? 'compute_attribute[vm_attrs]'
    : 'host[compute_attributes]';

  const [metaLoaded, setMetaLoaded] = useState(!!propsLoaded);
  const [metaError, setMetaError] = useState(false);
  const [metaNodes, setMetaNodes] = useState([]);
  const [metaPools, setMetaPools] = useState([]);
  const [metaStorages, setMetaStorages] = useState([]);
  const [metaBridges, setMetaBridges] = useState([]);
  const [metaImages, setMetaImages] = useState(images || []);

  useEffect(() => {
    if (registerComp) return undefined;
    if (metaLoaded) return undefined;
    if (!computeResourceId) return undefined;

    let isMounted = true;

    const fetchMetadata = async () => {
      try {
        const { data } = await API.get(
          `/foreman_fog_proxmox/metadata/${computeResourceId}`
        );
        if (!isMounted) return;
        setMetaNodes(data?.nodes || []);
        setMetaPools(data?.pools || []);
        setMetaStorages(data?.storages || []);
        setMetaBridges(data?.bridges || []);
        setMetaImages(data?.images || []);
        setMetaLoaded(true);
        setMetaError(false);
      } catch (error) {
        if (!isMounted) return;
        setMetaError(true);
        setMetaLoaded(true);
      }
    };

    fetchMetadata();

    return () => {
      isMounted = false;
    };
  }, [computeResourceId, metaLoaded, registerComp]);

  const nodesMap =
    metaNodes.length > 0
      ? metaNodes.map(node => ({ value: node.node, label: node.node }))
      : [];

  const imagesMap =
    metaImages.length > 0
      ? [
          { value: '', label: '' },
          ...metaImages.map(image => ({
            value: image.uuid,
            label: image.name,
          })),
        ]
      : [];

  const poolsMap =
    metaPools.length > 0
      ? [
          { value: '', label: '' },
          ...metaPools.map(pool => ({
            value: pool.poolid,
            label: pool.poolid,
          })),
        ]
      : [];

  const [filteredBridges, setFilteredBridges] = useState([]);

  const typeValue = general?.type?.value;
  const nodeIdValue = general?.nodeId?.value;

  useEffect(() => {
    if (!registerComp && !fromProfile) {
      networkSelected(typeValue);
    }
  }, [typeValue, registerComp, fromProfile]);

  useEffect(() => {
    if (registerComp) return;
    const filtered = metaBridges.filter(
      bridge => bridge.node_id === nodeIdValue
    );
    setFilteredBridges(filtered);
  }, [nodeIdValue, metaBridges, registerComp]);

  if (registerComp) {
    return null;
  }

  const componentMap = {
    qemu: {
      options: <ProxmoxServerOptions options={vmAttrs} />,
      hardware: <ProxmoxServerHardware hardware={vmAttrs} />,
      network: (
        <ProxmoxServerNetwork
          network={vmAttrs?.interfaces || []}
          bridges={filteredBridges}
          paramScope={paramScope}
        />
      ),
      storage: (
        <ProxmoxServerStorage
          storage={vmAttrs?.disks || []}
          efidisk={vmAttrs?.efidisk || []}
          storages={metaStorages}
          nodeId={general?.nodeId?.value}
          vmId={general?.vmid?.value}
          paramScope={paramScope}
          isLoading={!metaLoaded}
          isTabActive={activeTabKey === 4}
          computeResourceId={computeResourceId}
        />
      ),
    },
    lxc: {
      options: (
        <ProxmoxContainerOptions
          options={vmAttrs}
          storages={metaStorages}
          paramScope={paramScope}
          nodeId={general?.nodeId?.value}
          computeResourceId={computeResourceId}
        />
      ),
      hardware: <ProxmoxContainerHardware hardware={vmAttrs} />,
      network: (
        <ProxmoxContainerNetwork
          network={vmAttrs?.interfaces || []}
          bridges={filteredBridges}
          paramScope={paramScope}
        />
      ),
      storage: (
        <ProxmoxContainerStorage
          storage={vmAttrs?.disks || []}
          storages={metaStorages}
          nodeId={general?.nodeId?.value}
          paramScope={paramScope}
          isLoading={!metaLoaded}
          computeResourceId={computeResourceId}
          isTabActive={activeTabKey === 4}
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
    <ProxmoxBiosProvider>
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

        {!metaLoaded && (
          <PageSection padding={{ default: 'noPadding' }}>
            <Divider component="li" style={{ marginBottom: '1rem' }} />
            <Bullseye>
              <Spinner size="lg" />
            </Bullseye>
          </PageSection>
        )}

        {metaError && (
          <div style={{ color: '#c9190b', fontSize: '14px', marginTop: '8px' }}>
            {__(
              'Failed to load Proxmox metadata. Please check your compute resource connection.'
            )}
          </div>
        )}

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
    </ProxmoxBiosProvider>
  );
};

ProxmoxVmType.propTypes = {
  vmAttrs: PropTypes.object,
  images: PropTypes.array,
  fromProfile: PropTypes.bool,
  newVm: PropTypes.bool,
  registerComp: PropTypes.bool,
  untemplatable: PropTypes.bool,
  computeResourceId: PropTypes.number,
  propsLoaded: PropTypes.bool,
};

ProxmoxVmType.defaultProps = {
  vmAttrs: {},
  images: [],
  fromProfile: false,
  newVm: false,
  registerComp: false,
  untemplatable: false,
  computeResourceId: null,
  propsLoaded: false,
};

export default ProxmoxVmType;
