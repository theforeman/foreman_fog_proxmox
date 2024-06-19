import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  PageSection,
  Radio,
} from '@patternfly/react-core';
import InputField from '../../common/FormInputs';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';
import TimesIcon from '@patternfly/react-icons/dist/esm/icons/times-icon';
const CDRom = ({ onRemove, data }) => {
  const [cdrom, setCdrom] = useState('');

  const [selectedOption, setSelectedOption] = useState('');

  const handleMediaChange = (_, event) => {
    setSelectedOption(event.target.value);
  };

  const handleChange = (e) => {
    const { value } = e.target;
    setCdrom(value);
  };

  return (
    <div style={{ position: 'relative' }} >
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Title headingLevel="h4">CD-ROM  </Title>
        <button onClick={onRemove} ><TimesIcon/></button>
      </div>
      <Divider component="li" style={{ marginBottom: '1rem' }} />
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <Title headingLevel="h5">Media</Title>
      </div>
      <Divider component="li" style={{ marginBottom: '1rem' }} />
      <div style={{ display: 'flex', gap: '1rem' }}>
        <Radio
          id="radio-none"
          name="cdrom"
          label="None"
          value="None"
          isChecked={selectedOption === 'None'}
          onChange={handleMediaChange}
        />
        <Radio
          id="radio-physical"
          name="cdrom"
          label="Physical"
          value="Physical"
          isChecked={selectedOption === 'Physical'}
          onChange={handleMediaChange}
        />
        <Radio
          id="radio-image"
          name="cdrom"
          label="Image"
          value="Image"
          isChecked={selectedOption === 'Image'}
          onChange={handleMediaChange}
        />
      </div>
      {selectedOption === 'Image' && (
      <PageSection padding={{ default: 'noPadding' }}>
        <Title headingLevel="h5">Image</Title>
        <Divider component="li" style={{marginBottom: '2rem' }} />
	<InputField
	  label="Controller"
          type="select"
          value={cdrom}
	  options={ProxmoxComputeSelectors.proxmoxControllersCloudinitMap}
          onChange={handleChange}
        />
        <InputField
          label="Storage"
          type="text"
          value=""
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Image ISO"
          type="text"
          value=""
          onChange={handleChange}
        />
        <input
          type="hidden"
          value={cdrom}
          onChange={handleChange}
        />
	<input
          type="hidden"
          value={cdrom}
          onChange={handleChange}
        />
        <input
          name={cdrom}
          type="hidden"
          value={cdrom}
          onChange={handleChange}
        />
       </PageSection>
       )}
    </div>
  );
};

export default CDRom;
