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
import {Tabs, Tab, TabTitleText, Tooltip} from '@patternfly/react-core';
import {Table, Caption, Thead, Tr, Th, Tbody, Td} from '@patternfly/react-table';
import PlusCircleIcon from '@patternfly/react-icons/dist/esm/icons/plus-circle-icon';
import CPUFlagsModal from './components/CPUFlagsModal';

const cpuFlagNames = [
  'md_clear', 'pcid', 'spec_ctrl', 'ssbd', 'ibpb', 'virt_ssbd',
  'amd_ssbd', 'amd_no_ssb', 'pdpe1gb', 'hv_tlbflush', 'hv_evmcs', 'aes'
];

const cpuFlagDescriptions = {
  md_clear: 'Required to let the guest OS know if MDS is mitigated correctly',
  pcid: 'Meltdown fix cost reduction on Westmere, Sandy-, and IvyBridge Intel CPUs',
  spec_ctrl: 'Allows improved Spectre mitigation with Intel CPUs',
  ssbd: 'Protection for "Speculative Store Bypass" for Intel models',
  ibpb: 'Allows improved Spectre mitigation with AMD CPUs',
  virt_ssbd: 'Basis for "Speculative Store Bypass" protection for AMD models',
  amd_ssbd: 'Improves Spectre mitigation performance with AMD CPUs, best used with "virt-ssbd"',
  amd_no_ssb: 'Notifies guest OS that host is not vulnerable for Spectre on AMD CPUs',
  pdpe1gb: 'Allow guest OS to use 1GB size pages, if host HW supports it',
  hv_tlbflush: 'Improve performance in overcommitted Windows guests. May lead to guest bluescreens on old CPUs.',
  hv_evmcs: 'Improve performance for nested virtualization. Only supported on Intel CPUs.',
  aes: 'Activate AES instruction set for HW instruction'
};

const filterAndAddDescriptions = (hardware) => {
  return Object.keys(hardware)
    .filter(key => cpuFlagNames.includes(key))
    .reduce((acc, key) => {
      acc[key] = {
        ...hardware[key],
        description: cpuFlagDescriptions[key] || '',
	label: key
      };
      return acc;
    }, {});
};

const ProxmoxServerHardware = ({hardware}) => {
  const [hw, setHw] = useState(hardware);
  console.log("***************8 hwssssss", hw);

  const handleChange = (e) => {
    const { name, value } = e.target;
    const updatedKey = Object.keys(hw).find(key => hw[key].name === name);

    setHw(prevHw => ({
      ...prevHw,
      [updatedKey]: { ...prevHw[updatedKey], value: value },
    }));
  };
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleModalToggle = _event => {
    setIsModalOpen((prevIsModalOpen) => !prevIsModalOpen);
  };
  const cpuFlags = filterAndAddDescriptions(hw);

  return (
    <div>
      <PageSection padding={{ default: 'noPadding' }}>
            <Title headingLevel="h3">CPU</Title>
            <Divider component="li" style={{ marginBottom: '2rem' }} />
      <InputField
	      name={hw.cpu_type.name}
              label="Type"
              type="select"
              value={hw.cpu_type.value}
              options={ProxmoxComputeSelectors.proxmoxCpusMap}
              onChange={handleChange}
            />
            <InputField
	      name={hw.sockets.name}
              label="Sockets"
              type="number"
              value={hw.sockets.value}
              onChange={handleChange}
            />
            <InputField
	      name={hw.cores.name}
              label="Cores"
              type="number"
              value={hw.cores.value}
              onChange={handleChange}
            />
            <InputField
	      name={hw.vcpus.name}
              label="VCPUs"
              type="number"
              value={hw.vcpus.value}
              onChange={handleChange}
            />
            <InputField
	      name={hw.cpulimit.name}
              label="CPU limit"
              type="number"
              value={hw.cpulimit.value}
              onChange={handleChange}
            />
            <InputField
	      name={hw.cpuunits.name}
              label="CPU units"
              type="number"
              value={hw.cpuunits.value}
              onChange={handleChange}
            />
            <InputField
	      name={hw.numa.name}
              label="Enable NUMA"
              type="checkbox"
              value={hw.numa.value}
              onChange={handleChange}
            />
	  <div style={{ marginLeft: '5%', display: 'inline-block'}}>
	    <Button variant="link" onClick={handleModalToggle}>
        Extra CPU Flags
      </Button>
	  </div>
	  <CPUFlagsModal
	    isOpen={isModalOpen}
	    onClose={handleModalToggle}
            flags={cpuFlags}
            handleChange={handleChange}
          />
	  {Object.keys(cpuFlags).map(key => (
            <input
                key={hw[key].name}
                name={hw[key].name}
                type="hidden"
                value={hw[key].value}
            />
            ))}
	  </PageSection>
	    <PageSection padding={{ default: 'noPadding' }}>
	    <Title headingLevel="h3">Memory</Title>
            <Divider component="li" style={{ marginBottom: '2rem' }} />
            <InputField
	      name={hw.memory.name}
              label="Memory (MB)"
              type="text"
              value={hw.memory.value}
	      onChange={handleChange}
            />
            <InputField
	      name={hw.balloon.name}
              label="Minimum Memory (MB)"
              type="text"
              value={hw.balloon.value}
	      onChange={handleChange}
            />
            <InputField
	      name={hw.shares.name}
              label="Shares (MB)"
              type="text"
              value={hw.shares.value}
	      onChange={handleChange}
            />
	   </PageSection>
	    </div>
  );
};

export default ProxmoxServerHardware;
