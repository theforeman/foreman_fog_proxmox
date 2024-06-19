import React, { useState, useEffect } from 'react';
import NetworkInterface from './components/NetworkInterface';
import {
  Title,
  Divider,
  PageSection,
  Button,
} from '@patternfly/react-core';
import TimesIcon from '@patternfly/react-icons/dist/esm/icons/times-icon';
const ProxmoxContainerNetwork = ({network, bridges}) => {

  const [interfaces, setInterfaces] = useState([]);
  const [nextId, setNextId] = useState(0);
  const [availableIds, setAvailableIds] = useState([]);

  useEffect(() => {
    if (network && network.length > 0) {
      network.forEach((net) => {
	  console.log("****************8 net value", net.value)
          addInterface(null, net.value);
      });
    }
  }, [network]);

  const defaultInterface = {
      id: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][id]`, value: 'net0' },
      model: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][model]`, value: 'virtio' },
      bridge: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][bridge]`, value: bridges?.[0]?.iface },
      tag: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][tag]`, value: null },
      rate: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][rate]`, value: null },
      queues: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][queues]`, value: null }, 
      firewall: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][firewall]`, value: null },
      link_down: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][link_down]`, value: null },
    };

  const addInterface = (event, initData = defaultInterface ) => {
    if (event) event.preventDefault();
    const newId = availableIds.length > 0 ? availableIds[0] : nextId;
    if (availableIds.length > 0) {
      setAvailableIds(availableIds.slice(1));
    } else {
      setNextId(prevId => prevId + 1);
    }
    const newInterface = {
            id: newId,
            bridges: bridges,
            data: initData,
            networks: network,
        };
    setInterfaces(interfaces => [...interfaces, newInterface]);
  };

  const removeInterface = (idToRemove) => {
    const newInterfaces = interfaces.filter(nic => nic.props.id !== idToRemove);
    setInterfaces(newInterfaces);
    setAvailableIds([...availableIds, idToRemove].sort((a, b) => a - b));
  };

  return (
    <div>
      <PageSection padding={{ default: 'noPadding' }}>
	<Button onClick={addInterface} variant="secondary" >Add Interface</Button>
        {interfaces.map(nic => (
        <div key={nic.id} style={{ position: 'relative' }}>
          <div style={{ marginTop: '10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <Title headingLevel="h4"> Nic {nic.id} </Title>
          <button
              onClick={() => removeInterface(nic.props.id)}
              variant="plain"
          >
            <TimesIcon/>
          </button>
          </div>
          <NetworkInterface
              id={nic.id}
              data={nic.data}
              bridges={nic.bridges}
              networks={nic.networks}
            />
        </div>
      ))}
      </PageSection>
    </div>
  );
};

export default ProxmoxContainerNetwork;
