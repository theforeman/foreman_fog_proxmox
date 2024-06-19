import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  PageSection,
} from '@patternfly/react-core';
import InputField from '../../common/FormInputs';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';

const NetworkInterface = ({ id, networks, bridges, data }) => {
  const [network, setNetwork] = useState(data);
  
  const handleChange = (e) => {
    const { name, type, checked } = e.target;
    const value = type === "checkbox" ? (checked ? "1" : "0") : e.target.value;
    const updatedKey = Object.keys(network).find(key => network[key].name === name);
    const updatedData = { ...network, [updatedKey]: { ...network[updatedKey], value } };
    setNetwork(updatedData);
  };
  const bridgesMap = bridges.map(bridge => ({value: bridge.iface, label: bridge.iface }));
  return (
    <div style={{ position: 'relative' }} >
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
	  name={network.id.name}
          label="Indentifier"
          type="text"
          value={network.id.value}
          onChange={handleChange}
        />
        <InputField
	  name={network.model.name}
          label="Card"
          type="select"
          options={ProxmoxComputeSelectors.proxmoxNetworkcardsMap}
          value={network.model.value}
          onChange={handleChange}
        />
        <InputField
	  network={network.bridge.name}
          label="Bridge"
          type="select"
          options={bridgesMap}
          value={network.bridge.value}
          onChange={handleChange}
        />
        <InputField
	  name={network.tag.name}
          label="VLAN Tag"
          value={network.tag.value}
          onChange={handleChange}
        />
        <InputField
	  name={network.rate.name}
          label="Rate limit"
          value={network.rate.value}
          onChange={handleChange}
        />
        <InputField
	  name={network.queues.name}
          label="Multiqueue"
          type="text"
          value={network.queues.value}
          onChange={handleChange}
        />
        <InputField
	  name={network.firewall.name}
          label="Firewall"
          type="checkbox"
          value={network.firewall.value}
	  checked={network.firewall.value === "1"}
          onChange={handleChange}
        />
        <InputField
	  name={network.link_down.name}
          label="Disconnect"
          type="checkbox"
          value={network.link_down.value}
	  checked={network.link_down.value === "1"}
          onChange={handleChange}
        />
    </div>
  );
};

export default NetworkInterface;
