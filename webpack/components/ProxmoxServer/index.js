import React, { useState, useEffect } from 'react';
import {
  Button,
  Title,
  Divider,
  PageSection,
  ExpandableSection,
  ExpandableSectionToggle,
} from '@patternfly/react-core';
import Select from 'foremanReact/components/common/forms/Select';
import TextInput from 'foremanReact/components/common/forms/TextInput';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';
import NetworkInterface from './components/NetworkInterface';
import CloudInit from './components/CloudInit';
import HardDisk from './components/HardDisk';
import './customStyles.css';
import {Tabs, Tab, TabTitleText, Tooltip} from '@patternfly/react-core';
const cacheOptions = { key: 'Cached', value: 'No Cached' };

const ProxmoxServer = () => {
  const [selectedValue, setSelectedValue] = useState('Cached');

  const handleController = (val, e) => {
    setSelectedValue(e.target.value);
  };
  const [hdStorage, setHdStorage] = useState('');
  const handleHdStorage = (hdStorage, event) => {
    setHdStorage(hdStorage);
  };
  const [expanded, setExpanded] = useState('def-list-toggle2');

  const onToggle = id => {
    if (id === expanded) {
      setExpanded('');
    } else {
      setExpanded(id);
    }
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
  const [interfaces, setInterfaces] = useState([<NetworkInterface key={0} onRemove={() => removeInterface(0)} />]); // State to track A components

  const addInterface = (event) => {
    event.preventDefault();
    const newInterfaces = [...interfaces, <NetworkInterface key={interfaces.length} onRemove={() => removeInterface(interfaces.length)} />];
    setInterfaces(newInterfaces);
  };

  const removeInterface = (indexToRemove) => {
    const newInterfaces = interfaces.filter((_, index) => index !== indexToRemove);
    setInterfaces(newInterfaces);
  };

  const [hardDisks, setHardDisks] = useState([<HardDisk key={0} onRemove={() => removeHardDisk(0)} />]); // State to track A components

  const addHardDisk = (event) => {
    event.preventDefault();
    const newHardDisks = [...hardDisks, <HardDisk key={hardDisks.length} onRemove={() => removeHardDisk(hardDisks.length)} />];
    setHardDisks(newHardDisks);
  };

  const removeHardDisk = (indexToRemove) => {
    const newHardDisks = hardDisks.filter((_, index) => index !== indexToRemove);
    setHardDisks(newHardDisks);
  };

  const [cloudInit, setCloudInit] = useState(true);

  const addCloudInit = (event) => {
      setCloudInit(false);
  };

  const removeCloudInit = () => {
    setCloudInit(true);
  };

  const [cdRom, setCdRom] = useState(true);
  const addCdRom = (event) => {
      setCdRom(false);
  };

  const removeCdRom = () => {
    setCdRom(true);
  };

  return (
    <div>
          <ExpandableSection
            toggleText="Main Options"
            onToggle={onExpand}
            isExpanded={isExpanded}
	    className="customExpandableSection"
          >
            <InputField
              label="Description"
              type="textarea"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
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
          </ExpandableSection>
          <ExpandableSection
            toggleText="CPUs"
            onToggle={onsExpand}
            isExpanded={isOpen}
	    className="customExpandableSection"
          >
            <InputField
              label="Type"
              type="select"
              value={hdStorage}
              options={ProxmoxComputeSelectors.proxmoxCpusMap}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="Sockets"
              type="number"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="Cores"
              type="number"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="VCPUs"
              type="number"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="CPU limit"
              type="number"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="CPU units"
              type="number"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="Enable NUMA"
              type="checkbox"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
          </ExpandableSection>
          <ExpandableSection
            toggleText="Memory"
            onToggle={memExpand}
            isExpanded={memExpanded}
	    className="customExpandableSection"
          >
            <InputField
              label="Memory (MB)"
              type="text"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="Minimum Memory (MB)"
              type="text"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
            <InputField
              label="Shares (MB)"
              type="text"
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
          </ExpandableSection>
          <ExpandableSection
            toggleText="Operating System"
            onToggle={osExpand}
            isExpanded={osExpanded}
	    className="customExpandableSection"
          >
            <InputField
              label="OS Type"
              type="select"
              options={ProxmoxComputeSelectors.proxmoxOperatingSystemsMap}
              value={hdStorage}
              onChange={e => setHdStorage(e.target.value)}
            />
          </ExpandableSection>
	  <Button onClick={addInterface} variant="primary">Add Interface</Button>
	  {interfaces}
      {cloudInit && (
        <Button onClick={addCloudInit} variant="primary" size="sm"> Add Cloud-init </Button>
      )}
      {!cloudInit && (
        <CloudInit onRemove={removeCloudInit} />
      )}
       {'  '}
       {cdRom && (
        <Button onClick={addCdRom} variant="primary"> Add CD-ROM </Button>
      )}
      {!cdRom && (
        <CloudInit onRemove={removeCdRom} />
      )}
      {'  '}
      <Button onClick={addHardDisk} variant="primary">Add Hard Disk </Button>
          {hardDisks}	
    </div>
  );
};

export default ProxmoxServer;
