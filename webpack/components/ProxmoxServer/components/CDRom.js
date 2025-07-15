import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { Title, Divider, PageSection, Radio } from '@patternfly/react-core';
import { TimesIcon } from '@patternfly/react-icons';
import { translate as __ } from 'foremanReact/common/I18n';
import { imagesByStorage, createStoragesMap } from '../../ProxmoxStoragesUtils';
import InputField from '../../common/FormInputs';

const CDRom = ({ onRemove, data, storages, nodeId }) => {
  const [cdrom, setCdrom] = useState(data);
  const storagesMap = createStoragesMap(storages, 'iso', nodeId);
  const imagesMap = imagesByStorage(
    storages,
    nodeId,
    cdrom?.storage?.value,
    'iso'
  );

  const handleMediaChange = (_, e) => {
    setCdrom({
      ...cdrom,
      cdrom: {
        ...cdrom.cdrom,
        value: e.target.value,
      },
    });
  };

  const handleChange = e => {
    const { name, type, checked, value: targetValue } = e.target;
    let value;
    if (type === 'checkbox') {
      value = checked ? '1' : '0';
    } else {
      value = targetValue;
    }
    const updatedKey = Object.keys(cdrom).find(key => cdrom[key].name === name);
    const updatedData = {
      ...cdrom,
      [updatedKey]: { ...cdrom[updatedKey], value },
    };
    setCdrom(updatedData);
  };

  return (
    <div style={{ position: 'relative' }}>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <Title headingLevel="h4">{__('CD-ROM')}</Title>
        <button onClick={onRemove}>
          <TimesIcon />
        </button>
      </div>
      <Divider component="li" style={{ marginBottom: '1rem' }} />
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <Title headingLevel="h5">{__('Media')}</Title>
      </div>
      <Divider component="li" style={{ marginBottom: '1rem' }} />
      <div style={{ display: 'flex', gap: '1rem' }}>
        <Radio
          id="radio-none"
          name={cdrom?.cdrom?.name}
          label={__('None')}
          value="none"
          isChecked={cdrom?.cdrom?.value === 'none'}
          onChange={(e, _) => handleMediaChange(_, e)}
        />
        <Radio
          id="radio-physical"
          name={cdrom?.cdrom?.name}
          label={__('Physical')}
          value="physical"
          isChecked={cdrom?.cdrom?.value === 'physical'}
          onChange={(e, _) => handleMediaChange(_, e)}
        />
        <Radio
          id="radio-image"
          name={cdrom?.cdrom?.name}
          label={__('Image')}
          value="image"
          isChecked={cdrom?.cdrom?.value === 'image'}
          onChange={(e, _) => handleMediaChange(_, e)}
        />
      </div>
      {cdrom?.cdrom?.value === 'image' && (
        <PageSection padding={{ default: 'noPadding' }}>
          <Title headingLevel="h5">{__('Image')}</Title>
          <Divider component="li" style={{ marginBottom: '2rem' }} />
          <InputField
            label={__('Storage')}
            name={cdrom?.storage?.name}
            type="select"
            value={
              cdrom?.storage?.value ||
              (storagesMap?.length > 0 ? storagesMap[0].value : '')
            }
            options={storagesMap}
            onChange={handleChange}
          />
          <InputField
            name={cdrom?.volid?.name}
            label={__('Image ISO')}
            type="select"
            value={cdrom?.volid?.value}
            options={imagesMap}
            onChange={handleChange}
          />
          <input name={cdrom?.storageType?.name} type="hidden" value="cdrom" />
        </PageSection>
      )}
    </div>
  );
};

CDRom.propTypes = {
  onRemove: PropTypes.func.isRequired,
  data: PropTypes.shape({
    cdrom: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string.isRequired,
    }).isRequired,
    storage: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string,
    }).isRequired,
    volid: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string,
    }).isRequired,
    storageType: PropTypes.shape({
      name: PropTypes.string.isRequired,
    }).isRequired,
  }).isRequired,
  storages: PropTypes.array.isRequired,
  nodeId: PropTypes.string.isRequired,
};

export default CDRom;
