import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { translate as __ } from 'foremanReact/common/I18n';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';
import { useBios } from '../ProxmoxBiosContext';
import SecureBoot, { normalizeFirmwareOptions } from './components/SecureBoot';

const AGENT_OPTIONS = [
  ['agentFreezeFs', __('Freeze filesystems on backup')],
  ['agentFstrimClonedDisks', __('Trim cloned disks')],
];

const HOTPLUG_OPTIONS = [
  ['hotplugDisk', __('Disk')],
  ['hotplugNetwork', __('Network')],
  ['hotplugUsb', __('USB')],
  ['hotplugCpu', __('CPU')],
  ['hotplugMemory', __('Memory')],
];

const ProxmoxServerOptions = ({ options }) => {
  const [opts, setOpts] = useState(() => normalizeFirmwareOptions(options));

  const optionGroupStyle = {
    marginLeft: '30px',
    marginBottom: '15px',
    paddingLeft: '10px',
  };

  const { efiDiskSelected, setBios } = useBios();

  const handleChange = e => {
    const { name, type, checked, value: targetValue } = e.target;
    let value;
    if (type === 'checkbox') {
      value = checked ? '1' : '0';
    } else {
      value = targetValue;
    }

    const updatedKey = Object.keys(opts).find(key => opts[key].name === name);
    const updates = {
      [updatedKey]: { ...opts[updatedKey], value },
    };
    if (name === opts?.bios?.name) {
      updates.isSecureBoot = {
        ...opts.isSecureBoot,
        value: value === 'uefi_secure_boot' ? '1' : '0',
      };
      setBios(value);
    }

    setOpts(prevOpts => ({
      ...prevOpts,
      ...updates,
    }));
  };

  useEffect(() => {
    const biosValue = opts?.bios?.value;
    setBios(biosValue);
  }, [opts, setBios]);

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
        checked={String(opts?.onboot?.value) === '1'}
        onChange={handleChange}
      />
      <input type="hidden" name={opts?.agent?.name} value="0" />
      <InputField
        name={opts?.agent?.name}
        label={__('Qemu Agent')}
        info={__(
          'Enable/disable QEMU Guest Agent communication. The agent must be installed in the VM.'
        )}
        type="checkbox"
        value={opts?.agent?.value}
        checked={String(opts?.agent?.value) === '1'}
        onChange={handleChange}
      />
      {String(opts?.agent?.value) === '1' && (
        <div
          role="group"
          aria-label={__('Qemu Agent options')}
          style={optionGroupStyle}
        >
          {AGENT_OPTIONS.map(([key, label]) => (
            <InputField
              key={key}
              label={label}
              name={opts?.[key]?.name}
              type="checkbox"
              value="1"
              checked={String(opts?.[key]?.value) === '1'}
              onChange={handleChange}
            />
          ))}
          <InputField
            name={opts?.agentType?.name}
            label={__('Agent type')}
            type="select"
            value={opts?.agentType?.value}
            options={[
              { label: 'VirtIO', value: 'virtio' },
              { label: 'ISA', value: 'isa' },
            ]}
            onChange={handleChange}
          />
        </div>
      )}

      <input type="hidden" name={opts?.hotplug?.name} value="0" />
      <InputField
        name={opts?.hotplug?.name}
        label={__('Hotplug')}
        info={__('Enable/disable hotplug for selected devices')}
        type="checkbox"
        value={opts?.hotplug?.value}
        checked={String(opts?.hotplug?.value) === '1'}
        onChange={handleChange}
      />
      {String(opts?.hotplug?.value) === '1' && (
        <div
          role="group"
          aria-label={__('Hotplug devices')}
          style={optionGroupStyle}
        >
          {HOTPLUG_OPTIONS.map(([key, label]) => (
            <InputField
              key={key}
              label={label}
              name={opts?.[key]?.name}
              type="checkbox"
              value="1"
              checked={String(opts?.[key]?.value) === '1'}
              onChange={handleChange}
            />
          ))}
        </div>
      )}
      <InputField
        name={opts?.kvm?.name}
        label={__('KVM')}
        info={__('Enable/disable KVM hardware virtualization')}
        type="checkbox"
        value={opts?.kvm?.value}
        checked={String(opts?.kvm?.value) === '1'}
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
      <SecureBoot
        bios={opts?.bios}
        isSecureBoot={opts?.isSecureBoot}
        efiDiskSelected={efiDiskSelected}
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
