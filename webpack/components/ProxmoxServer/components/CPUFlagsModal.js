import React, { useState, useEffect } from 'react';
import { Form, Modal, Button, Slider } from '@patternfly/react-core';
import { Table, Thead, Tr, Th, Tbody, Td } from '@patternfly/react-table';
import InputField from '../../common/FormInputs';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';

const CPUFlagsModal = ({ isOpen, onClose, flags, handleChange }) => {
  return (
    <Modal
      bodyAriaLabel="Scrollable modal content"
      width="60%"
      tabIndex={0}
      title="CPU Flags"
      isOpen={isOpen}
      onClose={onClose}
      actions={[
        <Button key="confirm" variant="primary" onClick={onClose}>
          Confirm
        </Button>,
        <Button key="cancel" variant="link" onClick={onClose}>
          Cancel
        </Button>
      ]}
    >
      <Table aria-label="Simple table" variant="compact">
        <Thead>
          <Tr>
            <Th>Name</Th>
            <Th></Th>
            <Th>Description</Th>
          </Tr>
        </Thead>
        <Tbody>
          {Object.keys(flags).map(key => {
            const item = flags[key];
            return (
              <Tr key={item.label}>
                <Td>{item.label}</Td>
                <Td>
		  <select
                    name={item.name}
                    value={item.value}
                    onChange={handleChange}
                  >
		    {ProxmoxComputeSelectors.proxmoxCpuFlagsMap.map(flag => 
	              <option value={flag.value}>{flag.label}</option>)}
                  </select>
                </Td>
                <Td>{item.description}</Td>
              </Tr>
            );
          })}
        </Tbody>
      </Table>
    </Modal>
  );
};

export default CPUFlagsModal;
