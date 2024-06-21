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
const CDRom = ({ onRemove, data, storages, volids }) => {
  const [cdrom, setCdrom] = useState(data);
  const storagesMap = [{ value: '', label: '' }, {value: 'local', label: 'local'}];
  const imagesMap = [{ value: '', label: '' }, ...volids.map(v => ({value: v.volid, label: v.volid}))];
  const [selectedOption, setSelectedOption] = useState('');

  const handleMediaChange = (_, event) => {
    setSelectedOption(event.target.value);
  };

  const handleChange = (e) => {
    const { name, type, checked } = e.target;
    const value = type === "checkbox" ? (checked ? "1" : "0") : e.target.value;
    const updatedKey = Object.keys(cdrom).find(key => cdrom[key].name === name);
    const updatedData = { ...cdrom, [updatedKey]: { ...cdrom[updatedKey], value } };
    setCdrom(updatedData);
  };
  console.log("***************** data and volids, ", data, volids);
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
          name={cdrom.cdrom.name}
          label="None"
          value="None"
          isChecked={selectedOption === 'None'}
          onChange={handleMediaChange}
        />
        <Radio
          id="radio-physical"
          name={cdrom.cdrom.name}
          label="Physical"
          value="Physical"
          isChecked={selectedOption === 'Physical'}
          onChange={handleMediaChange}
        />
        <Radio
          id="radio-image"
          name={cdrom.cdrom.name}
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
          label="Storage"
          name={cdrom.storage.name}
          type="select"
          value={cdrom.storage.value}
	  options={storagesMap}
          onChange={handleChange}
        />
        <InputField
	  name={cdrom.volid.name}
          label="Image ISO"
          type="select"
          value={cdrom.volid.value}
	  options={imagesMap}
          onChange={handleChange}
        />
        <input
          name={cdrom.storage_type.name}
          type="hidden"
          value="cdrom"
        />
       </PageSection>
       )}
    </div>
  );
};

export default CDRom;
