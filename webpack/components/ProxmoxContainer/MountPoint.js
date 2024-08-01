import React, { useState } from 'react';
import { Divider } from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import PropTypes from 'prop-types';
import InputField from '../common/FormInputs';

const MountPoint = ({ id, data, storagesMap }) => {
  const [mp, setMp] = useState(data);
  const [error, setError] = useState('');

  const handleChange = e => {
    const { name, value } = e.target;
    const updatedKey = Object.keys(mp).find(key => mp[key].name === name);
    const updatedData = {
      ...mp,
      [updatedKey]: { ...mp[updatedKey], value },
    };
    setMp(updatedData);

    if (updatedKey === 'mp' && value.trim() === '') {
      setError(__('Path cannot be empty'));
    } else {
      setError('');
    }
  };

  return (
    <div>
      <Divider component="li" style={{ marginBottom: '2rem' }} />
      <InputField
        name={mp?.storage?.name}
        label={__('Storage')}
        type="select"
        options={storagesMap}
        value={mp?.storage?.value}
        onChange={handleChange}
      />
      <InputField
        name={mp?.mp?.name}
        label={__('Path')}
        required
        value={mp?.mp?.value}
        onChange={handleChange}
        error={error}
      />
      <InputField
        name={mp?.size?.name}
        label={__('Size (GB)')}
        type="number"
        value={mp?.size?.value}
        onChange={handleChange}
      />
      <InputField
        label={__('Device')}
        name={mp?.device?.name}
        disabled
        value={mp?.device?.value}
        onChange={handleChange}
        tooltip={__('Device value is set automatically.')}
      />
      <input
        name={mp?.id?.name}
        type="hidden"
        value={mp?.id?.value}
        onChange={handleChange}
      />
      <input
        name={mp?.volid?.name}
        type="hidden"
        value={mp?.volid?.value}
        onChange={handleChange}
      />
    </div>
  );
};

MountPoint.propTypes = {
  id: PropTypes.any.isRequired,
  data: PropTypes.object,
  storagesMap: PropTypes.array,
};

MountPoint.defaultProps = {
  data: {},
  storagesMap: [],
};

export default MountPoint;
