import React, { useState } from 'react';
import { Divider } from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import PropTypes from 'prop-types';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';

const MountPoint = ({ id, data, storagesMap }) => {
  const [mp, setMp] = useState(data);
  const [error, setError] = useState('');

  const handleChange = e => {
    const { name, type, checked, value: targetValue } = e.target;
    let value = targetValue;
    if (type === 'checkbox') {
      value = checked ? '1' : '0';
    }
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
        readOnly
        value={mp?.device?.value}
        onChange={handleChange}
        tooltip={__('Device value is set automatically.')}
      />
      <InputField
        name={mp?.backup?.name}
        label={__('Backup')}
        type="select"
        value={mp?.backup?.value}
        info={__('Enable/disable volume backup')}
        options={ProxmoxComputeSelectors.proxmoxBackupsMap}
        onChange={handleChange}
      />
      <InputField
        name={mp?.volid?.name}
        label={__('Host path (bind mount)')}
        info={__(
          'Optional. Set an absolute host directory (e.g. /host/dir) to create a bind mount instead of a storage-backed volume; leave the storage empty in that case.'
        )}
        value={mp?.volid?.value}
        onChange={handleChange}
      />
      <InputField
        name={mp?.ro?.name}
        label={__('Read-only')}
        type="checkbox"
        value={mp?.ro?.value}
        checked={String(mp?.ro?.value) === '1'}
        onChange={handleChange}
      />
      <InputField
        name={mp?.acl?.name}
        label={__('ACL')}
        type="checkbox"
        value={mp?.acl?.value}
        checked={String(mp?.acl?.value) === '1'}
        onChange={handleChange}
      />
      <InputField
        name={mp?.quota?.name}
        label={__('Quota')}
        type="checkbox"
        value={mp?.quota?.value}
        checked={String(mp?.quota?.value) === '1'}
        onChange={handleChange}
      />
      <InputField
        name={mp?.replicate?.name}
        label={__('Replicate')}
        type="checkbox"
        value={mp?.replicate?.value}
        checked={String(mp?.replicate?.value) === '1'}
        onChange={handleChange}
      />
      <InputField
        name={mp?.shared?.name}
        label={__('Shared')}
        type="checkbox"
        value={mp?.shared?.value}
        checked={String(mp?.shared?.value) === '1'}
        onChange={handleChange}
      />
      <InputField
        name={mp?.mountoptions?.name}
        label={__('Mount options')}
        info={__('Semicolon-separated fs mount options, e.g. noatime;nodev.')}
        value={mp?.mountoptions?.value}
        onChange={handleChange}
      />
      <input
        name={mp?.id?.name}
        type="hidden"
        value={mp?.id?.value}
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
