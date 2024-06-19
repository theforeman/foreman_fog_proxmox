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
  ExpandableSection,
  ExpandableSectionToggle,
} from '@patternfly/react-core';

const ProxmoxContainerOptions = ({options}) => {

  const [opts, setOpts] = useState(options);
  const handleChange = (e) => {
    const { name, value } = e.target;
    const updatedKey = Object.keys(opts).find(key => opts[key].name === name);

    setGeneral(prevOpts => ({
      ...prevOpts,
      [updatedKey]: { ...prevOpts[updatedKey], value: value },
    }));
  };

  return (
    <div>
	  <InputField
              name={opts.boot.name}
              label="Template Storage"
              value={opts.boot.value}
	      type="select"
              onChange={handleChange}
            />
	  <InputField
              name="[os_template]"
              label="OS Template"
              value={opts.boot.value}
	      type="select"
              onChange={handleChange}
            />
	  <InputField
              name={opts.boot.name}
              label="Root Password"
              value={opts.boot.value}
              onChange={handleChange}
            />
            <InputField
              name={opts.onboot.name}
              label="Start at boot"
              type="checkbox"
              value={opts.onboot.value}
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
	    <InputField
              name={opts.hostname.name}
              label="Hostname"
              value={opts.hostname.value}
              onChange={handleChange}
            />
	  <InputField
              name={opts.nameserver.name}
              label="DNS server"
              value={opts.nameserver.value}
              onChange={handleChange}
            />
	  <InputField
              name={opts.searchdomain.name}
              name='ostype'
              label="Search Domain"
              value={opts.searchdomain.value}
              onChange={handleChange}
            />
    </div>
  );
};

export default ProxmoxContainerOptions;

