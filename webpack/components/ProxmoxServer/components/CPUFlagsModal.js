import React from 'react';
import { Modal, Button } from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import { Thead, Tr, Th, Tbody, Td, Table } from '@patternfly/react-table';
import PropTypes from 'prop-types';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';

const CPUFlagsModal = ({ isOpen, onClose, flags, handleChange }) => {
  const resetFlags = () => {
    Object.keys(flags).forEach(key => {
      handleChange({
        target: {
          name: flags[key].name,
          value: '0',
        },
      });
    });
  };

  return (
    <div>
      <Modal
        ouiaId="proxmox-server-cpu-flags"
        bodyAriaLabel="Scrollable modal content"
        width="60%"
        tabIndex={0}
        title="CPU Flags"
        isOpen={isOpen}
        onClose={onClose}
        actions={[
          <Button
            ouiaId="proxmox-server-cpu-flags-confirm"
            key="confirm"
            variant="primary"
            onClick={onClose}
          >
            {__('Confirm')}
          </Button>,
          <Button
            ouiaId="proxmox-server-cpu-flags-reset"
            key="reset"
            variant="secondary"
            onClick={resetFlags}
          >
            {__('Reset')}
          </Button>,
        ]}
      >
        <Table
          ouiaId="proxmox-server-cpu-flags-table"
          aria-label="Simple table"
          variant="compact"
        >
          <Thead>
            <Tr ouiaId="proxmox-server-cpu-flags-tr1">
              <Th>Name</Th>
              <Th />
              <Th>Description</Th>
            </Tr>
          </Thead>
          <Tbody>
            {Object.keys(flags).map(key => {
              const item = flags[key];
              return (
                <Tr ouiaId="proxmox-server-cpu-flags-tr2" key={item.label}>
                  <Td>{item.label}</Td>
                  <Td>
                    <select
                      name={item.name}
                      value={item.value}
                      onChange={handleChange}
                    >
                      {ProxmoxComputeSelectors.proxmoxCpuFlagsMap.map(flag => (
                        <option value={flag.value}>{flag.label}</option>
                      ))}
                    </select>
                  </Td>
                  <Td>{item.description}</Td>
                </Tr>
              );
            })}
          </Tbody>
        </Table>
      </Modal>
    </div>
  );
};

CPUFlagsModal.propTypes = {
  isOpen: PropTypes.bool.isRequired,
  onClose: PropTypes.func.isRequired,
  flags: PropTypes.objectOf(
    PropTypes.shape({
      name: PropTypes.string.isRequired,
      label: PropTypes.string.isRequired,
      value: PropTypes.string.isRequired,
      description: PropTypes.string.isRequired,
    })
  ).isRequired,
  handleChange: PropTypes.func.isRequired,
};

export default CPUFlagsModal;
