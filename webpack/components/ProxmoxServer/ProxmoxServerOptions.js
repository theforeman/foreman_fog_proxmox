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

const ProxmoxServerOptions = ({options, onOptionsChange}) => {
  console.log('Props in ChildComponent:', {options, onOptionsChange});
  const handleChange = (e) => {
    onOptionsChange({...options, [e.target.name]:e.target.value});
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
	      name='boot'
              label="Boot device order"
              value={options.boot}
              onChange={handleChange}
            />
            <InputField
	      name='onboot'
              label="Start at boot"
              type="checkbox"
              value={options.onboot}
              onChange={handleChange}
            />
            <InputField
	      name='agent'
              label="Qemu Agent"
              type="checkbox"
              value={options.agent}
              onChange={handleChange}
            />
            <InputField
	      name='kvm'
              label="KVM"
              type="checkbox"
              value={options.kvm}
              onChange={handleChange}
            />
            <InputField
	      name='vga'
              label="VGA"
              type="select"
              value={options.vga}
              options={ProxmoxComputeSelectors.proxmoxVgasMap}
              onChange={handleChange}
            />
            <InputField
	      name='scsihw'
              label="SCSI Controller"
              type="select"
              value={options.scsihw}
              options={ProxmoxComputeSelectors.proxmoxScsiControllersMap}
              onChange={handleChange}
            />
            <InputField
	      name='bios'
              label="BIOS"
              type="select"
              options={ProxmoxComputeSelectors.proxmoxBiosMap}
              value={options.bios}
              onChange={handleChange}
            />
            <InputField
	      name='ostype'
              label="OS Type"
              type="select"
              options={ProxmoxComputeSelectors.proxmoxOperatingSystemsMap}
              value={options.ostype}
              onChange={handleChange}
            />
    </div>
  );
};

export default ProxmoxServerOptions;

