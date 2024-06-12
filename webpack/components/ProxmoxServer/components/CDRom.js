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
  const [cdrom, setCdrom] = useState(data);

  const [selectedOption, setSelectedOption] = useState('');

  const handleMediaChange = (_, event) => {
    setSelectedOption(event.target.value);
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    const updatedKey = Object.keys(cdrom).find(key => cdrom[key].name === name);
    console.log("************ updated key", updatedKey);

    const updatedData = { ...cdrom, [updatedKey]: { ...cdrom[updatedKey], value } };
    setCdrom(updatedData);
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
          name={cdrom.controller.name}
          type="select"
          value={cdrom.controller.value}
	  options={ProxmoxComputeSelectors.proxmoxControllersCloudinitMap}
          onChange={handleChange}
        />
        <InputField
          label="Storage"
	  name={cdrom.storage.name}
          type="text"
          value={cdrom.storage.value}
          onChange={e => setHdStorage(e.target.value)}
        />
        <InputField
          label="Image ISO"
	  name={cdrom.volid.name}
          type="select"
          options={ProxmoxComputeSelectors.proxmoxControllersCloudinitMap}
          value={cdrom.volid.value}
          onChange={handleChange}
        />
        <input
          name={cdrom.id.name}
          type="hidden"
          value={cdrom.id.value}
          onChange={handleChange}
        />
	<input
          name={cdrom.storage_type.name}
          type="hidden"
          value={cdrom.storage_type.value}
          onChange={handleChange}
        />
        <input
          name={cdrom.device.name}
          type="hidden"
          value={cdrom.device.value}
          onChange={handleChange}
        />
       </PageSection>
       )}
    </div>
  );
};

export default CDRom;
