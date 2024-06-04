import React, { useState, useEffect } from 'react';
import InputField from '../common/FormInputs';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';
import {
  FormGroup,
  TextContent,
  Text,
  PageSection,
  Title,
  Divider,
  SelectOption,
} from '@patternfly/react-core';

const ProxmoxServerOptions = ({options}) => {
  const [opts, setOpts] = useState(options);

  const handleChange = (e) => {
    const { name, type, checked } = e.target;
    const value = type === "checkbox" ? (checked ? "1" : "0") : e.target.value;
    const updatedKey = Object.keys(opts).find(key => opts[key].name === name);
    setOpts(prevOpts => ({
      ...prevOpts,
      [updatedKey]: { ...prevOpts[updatedKey], value: value },
    }));
  };
  
  return (
    <div>
            <InputField
	      name={opts.boot.name}
              label="Boot device order"
              value={opts.boot.value}
              onChange={handleChange}
            />
            <InputField
	      name={opts.onboot.name}
              label="Start at boot"
              type="checkbox"
              value={opts.onboot.value}
	      checked={opts.onboot.value === "1"}
              onChange={handleChange}
            />
            <InputField
	      name={opts.agent.name}
              label="Qemu Agent"
              type="checkbox"
              value={opts.agent.value}
	      checked={opts.agent.value === "1"}
              onChange={handleChange}
            />
            <InputField
	      name={opts.kvm.name}
              label="KVM"
              type="checkbox"
              value={opts.kvm.value}
	      checked={opts.kvm.value === "1"}
              onChange={handleChange}
            />
            <InputField
	      name={opts.vga.name}
              label="VGA"
              type="select"
              value={opts.vga.value}
              options={ProxmoxComputeSelectors.proxmoxVgasMap}
              onChange={handleChange}
            />
            <InputField
	      name={opts.scsihw.name}
              label="SCSI Controller"
              type="select"
              value={opts.scsihw.value}
              options={ProxmoxComputeSelectors.proxmoxScsiControllersMap}
              onChange={handleChange}
            />
            <InputField
	      name={opts.bios.name}
              label="BIOS"
              type="select"
              options={ProxmoxComputeSelectors.proxmoxBiosMap}
              value={opts.bios.value}
              onChange={handleChange}
            />
            <InputField
	      name={opts.ostype.name}
              label="OS Type"
              type="select"
              options={ProxmoxComputeSelectors.proxmoxOperatingSystemsMap}
              value={opts.ostype.value}
              onChange={handleChange}
            />
    </div>
  );
};

export default ProxmoxServerOptions;

