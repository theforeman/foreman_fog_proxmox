import React, { useState, useEffect } from 'react';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';
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
import './customStyles.css';
import {Tabs, Tab, TabTitleText, Tooltip} from '@patternfly/react-core';
const cacheOptions = { key: 'Cached', value: 'No Cached' };

const ProxmoxServerOptions = () => {
  const [hdStorage, setHdStorage] = useState('');
  const handleHdStorage = (hdStorage, event) => {
    setHdStorage(hdStorage);
  };


  const [isExpanded, setIsExpanded] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const [memExpanded, setMemExpanded] = useState(false);
  const [osExpanded, setOsExpanded] = useState(false);
  const onExpand = () => {
    setIsExpanded(!isExpanded);
  };

  const onsExpand = () => {
    setIsOpen(!isOpen);
  };

  const memExpand = () => {
    setMemExpanded(!memExpanded);
  };

  const osExpand = () => {
    setOsExpanded(!osExpanded);
  };

  return (
    <div>
            <InputField
              label="Boot device order"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="Start at boot"
              type="checkbox"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="Qemu Agent"
              type="checkbox"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="KVM"
              type="checkbox"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="VGA"
              type="select"
              value={hdStorage}
              options={ProxmoxComputeSelectors.proxmoxVgasMap}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="SCSI Controller"
              type="select"
              value={hdStorage}
              options={ProxmoxComputeSelectors.proxmoxScsiControllersMap}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="BIOS"
              type="select"
              options={ProxmoxComputeSelectors.proxmoxBiosMap}
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="OS Type"
              type="select"
              options={ProxmoxComputeSelectors.proxmoxOperatingSystemsMap}
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
    </div>
  );
};

export default ProxmoxServerOptions;

