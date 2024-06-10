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
const CDRom = ({ onRemove }) => {
  const [cdrom, setCdrom] = useState('');

  const [hdStorage, setHdStorage] = useState('');
  const handleHdStorage = (hdStorage, event) => {
    setHdStorage(hdStorage);
  };
  const [selectedOption, setSelectedOption] = useState('');

  const handleChange = (_, event) => {
    setSelectedOption(event.target.value);
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
          onChange={handleChange}
        />
        <Radio
          id="radio-physical"
          ame="cdrom"
          label="Physical"
          value="Physical"
          isChecked={selectedOption === 'Physical'}
          onChange={handleChange}
        />
        <Radio
          id="radio-image"
          name="cdrom"
          label="Image"
          value="Image"
          isChecked={selectedOption === 'Image'}
          onChange={handleChange}
        />
      </div>
      {selectedOption === 'Image' && (
      <PageSection padding={{ default: 'noPadding' }}>
        <Title headingLevel="h5">Image</Title>
        <Divider component="li" style={{marginBottom: '2rem' }} />
        <InputField
          label="Storage"
          type="text"
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Image ISO"
          type="select"
          options={ProxmoxComputeSelectors.proxmoxControllersCloudinitMap}
          value={hdStorage}
          onChange={e => setHdStorage(e.target.value)}
        />
       </PageSection>
       )}
    </div>
  );
};

export default CDRom;
