import React, { useState, useEffect } from 'react';
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
import ProxmoxComputeSelectors from './ProxmoxComputeSelectors';
import ProxmoxServer from './ProxmoxServer';
import Select from 'foremanReact/components/common/forms/Select';
import InputField from './common/FormInputs';
import TextInput from 'foremanReact/components/common/forms/TextInput';

const ProxmoxVmType = ({ computeResource, types_map, new_vm }) => {
  const [selectedValue, setSelectedValue] = useState('qemu');
  const [vmId, setVmId] = useState('');
  const [image, setImage] = useState('');
  const [pool, setPool] = useState('');
  const [node, setNode] = useState('');

  const handleVmType = e => {
    setSelectedValue(e.target.value);
  };

  const handleChange = ({}) => {
    console.log('**********************8, e.target');
  };

  const renderSelectedForm = () => {
    console.log(
      '***********selected type',
      ProxmoxComputeSelectors.proxmoxCpuFlagsMap.map(option => (
        <option value={option.value}>{option.label}</option>
      ))
    );
    console.log('****************8 slected cavlue', selectedValue);
    switch (selectedValue) {
      case 'qemu':
        return <ProxmoxServer />;
      case 'lxc':
        return null;
      default:
        return null;
    }
  };

  const typesOptions = { qemu: 'KVM/Qemu server', lxc: 'LXC container' };

  const proxmoxTypesMap = [
    { value: 'qemu', label: 'KVM/Qemu server' },
    { value: 'lxc', label: 'LXC container' },
  ];

  return (
    <div>
      <InputField
        label="Type"
        required
        onChange={e => setSelectedValue(e.target.value)}
        value={selectedValue}
        options={ProxmoxComputeSelectors.proxmoxTypesMap}
        type="select"
      />
      <PageSection padding={{ default: 'noPadding' }}>
        <Title headingLevel="h3">General</Title>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          label="VM ID"
          required
          type="number"
          value={vmId}
          onChange={e => setVmId(e.target.value)}
        />
        <InputField
          label="Node"
          required
          type="select"
          value={node}
          options={proxmoxTypesMap}
          onChange={e => setNode(e.target.value)}
        />
        <InputField
          label="Image"
          type="select"
          value={image}
          options={proxmoxTypesMap}
          onChange={e => setImage(e.target.value)}
        />
        <InputField
          label="Pool"
          type="select"
          value={pool}
          options={proxmoxTypesMap}
          onChange={e => setPool(e.target.value)}
        />
      </PageSection>
      {renderSelectedForm()}
    </div>
  );
};

export default ProxmoxVmType;
