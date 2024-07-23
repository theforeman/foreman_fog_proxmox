import React, { useState } from 'react';
import { Button, Title, Divider, PageSection } from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import PropTypes from 'prop-types';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';
import CPUFlagsModal from './components/CPUFlagsModal';

const cpuFlagNames = [
  'md_clear',
  'pcid',
  'spec_ctrl',
  'ssbd',
  'ibpb',
  'virt_ssbd',
  'amd_ssbd',
  'amd_no_ssb',
  'pdpe1gb',
  'hv_tlbflush',
  'hv_evmcs',
  'aes',
];

const cpuFlagDescriptions = {
  md_clear: __(
    'Required to let the guest OS know if MDS is mitigated correctly'
  ),
  pcid: __(
    'Meltdown fix cost reduction on Westmere, Sandy-, and IvyBridge Intel CPUs'
  ),
  spec_ctrl: __('Allows improved Spectre mitigation with Intel CPUs'),
  ssbd: __('Protection for "Speculative Store Bypass" for Intel models'),
  ibpb: __('Allows improved Spectre mitigation with AMD CPUs'),
  virt_ssbd: __(
    'Basis for "Speculative Store Bypass" protection for AMD models'
  ),
  amd_ssbd: __(
    'Improves Spectre mitigation performance with AMD CPUs, best used with "virt-ssbd"'
  ),
  amd_no_ssb: __(
    'Notifies guest OS that host is not vulnerable for Spectre on AMD CPUs'
  ),
  pdpe1gb: __('Allow guest OS to use 1GB size pages, if host HW supports it'),
  hv_tlbflush: __(
    'Improve performance in overcommitted Windows guests. May lead to guest bluescreens on old CPUs.'
  ),
  hv_evmcs: __(
    'Improve performance for nested virtualization. Only supported on Intel CPUs.'
  ),
  aes: __('Activate AES instruction set for HW instruction'),
};

const filterAndAddDescriptions = hardware =>
  Object.keys(hardware)
    .filter(key => cpuFlagNames.includes(key))
    .reduce((acc, key) => {
      acc[key] = {
        ...hardware[key],
        description: cpuFlagDescriptions[key] || '',
        label: key,
      };
      return acc;
    }, {});

const ProxmoxServerHardware = ({ hardware }) => {
  const [hw, setHw] = useState(hardware);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const handleChange = e => {
    const { name, type, checked, value: targetValue } = e.target;
    let value;
    if (type === 'checkbox') {
      value = checked ? '1' : '0';
    } else {
      value = targetValue;
    }
    const updatedKey = Object.keys(hw).find(key => hw[key].name === name);

    setHw(prevHw => ({
      ...prevHw,
      [updatedKey]: { ...prevHw[updatedKey], value },
    }));
  };

  const handleModalToggle = _event => {
    setIsModalOpen(prevIsModalOpen => !prevIsModalOpen);
  };

  const cpuFlags = filterAndAddDescriptions(hw);

  return (
    <div>
      <PageSection padding={{ default: 'noPadding' }}>
        <Title headingLevel="h3">{__('CPU')}</Title>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          name={hw?.cpuType?.name}
          label={__('Type')}
          type="select"
          value={hw?.cpuType?.value}
          options={ProxmoxComputeSelectors.proxmoxCpusMap}
          onChange={handleChange}
        />
        <InputField
          name={hw?.sockets?.name}
          label={__('Sockets')}
          type="number"
          value={hw?.sockets?.value}
          onChange={handleChange}
        />
        <InputField
          name={hw?.cores?.name}
          label={__('Cores')}
          type="number"
          value={hw?.cores?.value}
          onChange={handleChange}
        />
        <InputField
          name={hw?.vcpus?.name}
          label={__('VCPUs')}
          type="number"
          value={hw?.vcpus?.value}
          onChange={handleChange}
        />
        <InputField
          name={hw?.cpulimit?.name}
          label={__('CPU limit')}
          type="number"
          value={hw?.cpulimit?.value}
          onChange={handleChange}
        />
        <InputField
          name={hw?.cpuunits?.name}
          label={__('CPU units')}
          type="number"
          value={hw?.cpuunits?.value}
          onChange={handleChange}
        />
        <InputField
          name={hw?.numa?.name}
          label={__('Enable NUMA')}
          type="checkbox"
          value={hw?.numa?.value}
          checked={hw?.numa?.value === '1'}
          onChange={handleChange}
        />
        <div style={{ marginLeft: '5%', display: 'inline-block' }}>
          <Button variant="link" onClick={handleModalToggle}>
            {__('Extra CPU Flags')}
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
        <Title headingLevel="h3">{__('Memory')}</Title>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          name={hw?.memory?.name}
          label={__('Memory (MB)')}
          type="text"
          value={hw?.memory?.value}
          onChange={handleChange}
        />
        <InputField
          name={hw?.balloon?.name}
          label={__('Minimum Memory (MB)')}
          type="text"
          value={hw?.balloon?.value}
          onChange={handleChange}
        />
        <InputField
          name={hw?.shares?.name}
          label={__('Shares (MB)')}
          type="text"
          value={hw?.shares?.value}
          onChange={handleChange}
        />
      </PageSection>
    </div>
  );
};

ProxmoxServerHardware.propTypes = {
  hardware: PropTypes.object,
};

ProxmoxServerHardware.defaultProps = {
  hardware: {},
};

export default ProxmoxServerHardware;
