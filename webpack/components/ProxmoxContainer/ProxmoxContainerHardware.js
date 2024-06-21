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

const ProxmoxContainerHardware = ({hardware}) => {

  const [hw, setHw] = useState(hardware);

  const handleChange = (e) => {
    const { name, value } = e.target;
    const updatedKey = Object.keys(hw).find(key => hw[key].name === name);

    setHw(prevHw => ({
      ...prevHw,
      [updatedKey]: { ...prevHw[updatedKey], value: value },
    }));
  };

  return (
    <div>
      <PageSection padding={{ default: 'noPadding' }}>
            <Title headingLevel="h3">CPU</Title>
            <Divider component="li" style={{ marginBottom: '2rem' }} />
	    <InputField
	      name={hw.arch.name}
              label="Arctitecture"
              type="select"
	      options={ProxmoxComputeSelectors.proxmoxCpuFlagsMap}
              value={hw.arch.value}
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
	      name={hw.swap.name}
              label="Swap (MB)"
              type="text"
              value={hw.swap.value}
              onChange={handleChange}
            />
           </PageSection>
 </div>
  );
};

export default ProxmoxContainerHardware;

