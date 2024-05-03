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

const ProxmoxServerHardware = () => {
  const [selectedValue, setSelectedValue] = useState('Cached');

  const handleController = (val, e) => {
    setSelectedValue(e.target.value);
  };
  const [hdStorage, setHdStorage] = useState('');
  const handleHdStorage = (hdStorage, event) => {
    setHdStorage(hdStorage);
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
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
	     </Td>
            <Td>Required to let the guest OS know if MDS is mitigated correctly</Td>
            </Tr>
	  <Tr>
            <Td>pcid</Td>
	    <Td>
	      <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
              </Td>
            <Td>Meltdown fix cost reduction on Westmere, Sandy-, and IvyBridge Intel CPUs</Td>
            </Tr>
	  <Tr>
            <Td>spec-ctrl</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
	    </Td>
            <Td>Allows improved Spectre mitigation with Intel CPUs</Td>
            </Tr>
	  <Tr>
            <Td>ssbd</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
              </Td>
            <Td>Protection for "Speculative Store Bypass" for Intel models</Td>
            </Tr>
	  <Tr>
            <Td>ibpb</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
              </Td>
            <Td>Allows improved Spectre mitigation with AMD CPUs</Td>
            </Tr>
	  <Tr>
            <Td>virt-ssbd</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
              </Td>
            <Td>Basis for "Speculative Store Bypass" protection for AMD models</Td>
            </Tr>
	  <Tr>
            <Td>amd-ssbd</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
              </Td>
            <Td>Improves Spectre mitigation performance with AMD CPUs, best used with "virt-ssbd"</Td>
            </Tr>
	  <Tr>
            <Td>amd-no-ssb</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
              </Td>
            <Td>Notifies guest OS that host is not vulnerable for Spectre on AMD CPUs</Td>
            </Tr>
	  <Tr>
            <Td>pdpe1gb</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
              </Td>
            <Td>Allow guest OS to use 1GB size pages, if host HW supports it</Td>
            </Tr>
	  <Tr>
            <Td>hv-tlbflush</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
              </Td>
            <Td>Improve performance in overcommitted Windows guests. May lead to guest bluescreens on old CPUs.</Td>
            </Tr>
	  <Tr>
            <Td>hv-evmcs</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
              />
	     </Td>
            <Td>Improve performance for nested virtualization. Only supported on Intel CPUs.</Td>
            </Tr>
	  <Tr>
            <Td>aes</Td>
            <Td>
	     <InputField
                type="select"
                value={hdStorage}
                options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
                onChange={e => setHdStorage(e.target.value)}
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
	   </PageSection>
	    </div>
  );
};

export default ProxmoxServerHardware;
