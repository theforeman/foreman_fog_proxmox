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
import './customStyles.css';
import {Tabs, Tab, TabTitleText, Tooltip} from '@patternfly/react-core';
import {Table, Caption, Thead, Tr, Th, Tbody, Td} from '@patternfly/react-table';
import PlusCircleIcon from '@patternfly/react-icons/dist/esm/icons/plus-circle-icon';
const cacheOptions = { key: 'Cached', value: 'No Cached' };

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
	    <Button variant="link" icon={<PlusCircleIcon />} onClick={handleModalToggle}>
        Extra CPU Flags
      </Button>
      <Modal
        bodyAriaLabel="Scrollable modal content"
	width="50%"
        tabIndex={0}
        title="CPU Flags"
        isOpen={isModalOpen}
        onClose={handleModalToggle}
        actions={[
	  <Button key="confirm" variant="primary" onClick={handleModalToggle}>
            Confirm
          </Button>,
          <Button key="cancel" variant="link" onClick={handleModalToggle}>
            Cancel
          </Button>
        ]}
      >  
        <Table aria-label="Simple table" variant='compact'>
	  <Thead>
          <Tr>
	    <Th>Name</Th>
	    <Th></Th>
            <Th>Description</Th>
	  </Tr>
	  </Thead>
        <Tbody>
            <Tr>
            <Td>md-clear</Td>
	    <Td>
              <InputField
	        name={hw.md_clear.name}
                type="select"
                value={hw.md_clear.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
	     </Td>
            <Td>Required to let the guest OS know if MDS is mitigated correctly</Td>
            </Tr>
	  <Tr>
            <Td>pcid</Td>
	    <Td>
	      <InputField
	        name={hw.pcid.name}
                type="select"
                value={hw.pcid.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
              </Td>
            <Td>Meltdown fix cost reduction on Westmere, Sandy-, and IvyBridge Intel CPUs</Td>
            </Tr>
	  <Tr>
            <Td>spec-ctrl</Td>
            <Td>
	     <InputField
	        name={hw.spectre.name}
                type="select"
                value={hw.spectre.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
	    </Td>
            <Td>Allows improved Spectre mitigation with Intel CPUs</Td>
            </Tr>
	  <Tr>
            <Td>ssbd</Td>
            <Td>
	     <InputField
	        name={hw.ssbd.name}
                type="select"
                value={hw.ssbd.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
              </Td>
            <Td>Protection for "Speculative Store Bypass" for Intel models</Td>
            </Tr>
	  <Tr>
            <Td>ibpb</Td>
            <Td>
	     <InputField
	        name={hw.ibpb.name}
                type="select"
                value={hw.ibpb.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
              </Td>
            <Td>Allows improved Spectre mitigation with AMD CPUs</Td>
            </Tr>
	  <Tr>
            <Td>virt-ssbd</Td>
            <Td>
	     <InputField
	        name={hw.virt_ssbd.name}
                type="select"
                value={hw.virt_ssbd.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
              </Td>
            <Td>Basis for "Speculative Store Bypass" protection for AMD models</Td>
            </Tr>
	  <Tr>
            <Td>amd-ssbd</Td>
            <Td>
	     <InputField
	        name={hw.amd_ssbd.name}
                type="select"
                value={hw.amd_ssbd.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
              </Td>
            <Td>Improves Spectre mitigation performance with AMD CPUs, best used with "virt-ssbd"</Td>
            </Tr>
	  <Tr>
            <Td>amd-no-ssb</Td>
            <Td>
	     <InputField
	        name={hw.amd_no_ssb.name}
                type="select"
                value={hw.amd_no_ssb.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
              </Td>
            <Td>Notifies guest OS that host is not vulnerable for Spectre on AMD CPUs</Td>
            </Tr>
	  <Tr>
            <Td>pdpe1gb</Td>
            <Td>
	     <InputField
	        name={hw.pdpe1gb.name}
                type="select"
                value={hw.pdpe1gb.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
              </Td>
            <Td>Allow guest OS to use 1GB size pages, if host HW supports it</Td>
            </Tr>
	  <Tr>
            <Td>hv-tlbflush</Td>
            <Td>
	     <InputField
	        name={hw.hv_tlbflush.name}
                type="select"
                value={hw.hv_tlbflush.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
              </Td>
            <Td>Improve performance in overcommitted Windows guests. May lead to guest bluescreens on old CPUs.</Td>
            </Tr>
	  <Tr>
            <Td>hv-evmcs</Td>
            <Td>
	     <InputField
	        name={hw.hv_evmcs.name}
                type="select"
                value={hw.hv_evmcs.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
	     </Td>
            <Td>Improve performance for nested virtualization. Only supported on Intel CPUs.</Td>
            </Tr>
	  <Tr>
            <Td>aes</Td>
            <Td>
	     <InputField
	        name={hw.aes.name}
                type="select"
                value={hw.aes.value}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
	        onChange={handleChange}
              />
	     </Td>
            <Td>Activate AES instruction set for HW instruction</Td>
	    </Tr>
	  </Tbody>
      </Table>
	    </Modal>
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
