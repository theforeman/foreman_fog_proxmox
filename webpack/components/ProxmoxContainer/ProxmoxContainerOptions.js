import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { translate as __ } from 'foremanReact/common/I18n';
import { createStoragesMap, imagesByStorage } from '../ProxmoxStoragesUtils';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';
import InputField from '../common/FormInputs';

const ProxmoxContainerOptions = ({ options, storages, nodeId }) => {
  const [opts, setOpts] = useState(options);
  const storagesMap = createStoragesMap(storages, 'vztmpl', nodeId);
  const volumesMap = imagesByStorage(storages, nodeId, 'local', 'vztmpl');
  const handleChange = e => {
    const { name, type, checked, value: targetValue } = e.target;
    let value;
    if (type === 'checkbox') {
      value = checked ? '1' : '0';
    } else {
      value = targetValue;
    }
    const updatedKey = Object.keys(opts).find(key => opts[key].name === name);

    setOpts(prevOpts => ({
      ...prevOpts,
      [updatedKey]: { ...prevOpts[updatedKey], value },
    }));
  };
  return (
    <div>
      <InputField
        name={opts?.ostemplateStorage?.name}
        label={__('Template Storage')}
        value={opts?.ostemplateStorage?.value}
        options={storagesMap}
        type="select"
        onChange={handleChange}
      />
      <InputField
        name={opts?.ostemplateFile?.name}
        label={__('OS Template')}
        required
        options={volumesMap}
        value={opts?.ostemplateFile?.value}
        type="select"
        onChange={handleChange}
      />
      <InputField
        name={opts?.password?.name}
        label={__('Root Password')}
        required
        type="password"
        value={opts?.password?.value}
        onChange={handleChange}
      />
      <InputField
        name={opts?.onboot?.name}
        label={__('Start at boot')}
        type="checkbox"
        value={opts?.onboot?.value}
        checked={opts?.onboot?.value === '1'}
        onChange={handleChange}
      />
      <InputField
        name={opts?.ostype?.name}
        label={__('OS Type')}
        type="select"
        options={ProxmoxComputeSelectors.proxmoxOperatingSystemsMap}
        value={opts?.ostype?.value}
        onChange={handleChange}
      />
      <InputField
        name={opts?.hostname?.name}
        label={__('Hostname')}
        value={opts?.hostname?.value}
        onChange={handleChange}
      />
      <InputField
        name={opts?.nameserver?.name}
        label={__('DNS server')}
        value={opts?.nameserver?.value}
        onChange={handleChange}
      />
      <InputField
        name={opts?.searchdomain?.name}
        label={__('Search Domain')}
        value={opts?.searchdomain?.value}
        onChange={handleChange}
      />
    </div>
  );
};

ProxmoxContainerOptions.propTypes = {
  options: PropTypes.object,
  storages: PropTypes.array,
  nodeId: PropTypes.string,
};

ProxmoxContainerOptions.defaultProps = {
  options: {},
  storages: [],
  nodeId: '',
};

export default ProxmoxContainerOptions;
