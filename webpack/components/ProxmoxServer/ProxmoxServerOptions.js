import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { translate as __ } from 'foremanReact/common/I18n';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';

const ProxmoxServerOptions = ({ options }) => {
  const [opts, setOpts] = useState(options);

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
        name={opts?.boot?.name}
        label={__('Boot device order')}
        info={__(
          'Order your devices, e.g. order=net0;ide2;scsi0. Default empty (any)'
        )}
        value={opts?.boot?.value}
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
        name={opts?.agent?.name}
        label={__('Qemu Agent')}
        type="checkbox"
        value={opts?.agent?.value}
        checked={opts?.agent?.value === '1'}
        onChange={handleChange}
      />
      <InputField
        name={opts?.kvm?.name}
        label={__('KVM')}
        info={__('Enable/disable KVM hardware virtualization')}
        type="checkbox"
        value={opts?.kvm?.value}
        checked={opts?.kvm?.value === '1'}
        onChange={handleChange}
      />
      <InputField
        name={opts?.vga?.name}
        label={__('VGA')}
        type="select"
        value={opts?.vga?.value}
        options={ProxmoxComputeSelectors.proxmoxVgasMap}
        onChange={handleChange}
      />
      <InputField
        name={opts?.scsihw?.name}
        label={__('SCSI Controller')}
        type="select"
        value={opts?.scsihw?.value}
        options={ProxmoxComputeSelectors.proxmoxScsiControllersMap}
        onChange={handleChange}
      />
      <InputField
        name={opts?.bios?.name}
        label={__('BIOS')}
        type="select"
        options={ProxmoxComputeSelectors.proxmoxBiosMap}
        value={opts?.bios?.value}
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
    </div>
  );
};

ProxmoxServerOptions.propTypes = {
  options: PropTypes.object,
};

ProxmoxServerOptions.defaultProps = {
  options: {},
};

export default ProxmoxServerOptions;
