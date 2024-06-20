import React, { useState, useEffect } from 'react';
import NetworkInterface from './components/NetworkInterface';
import {
  Title,
  Divider,
  PageSection,
  Button,
} from '@patternfly/react-core';
import TimesIcon from '@patternfly/react-icons/dist/esm/icons/times-icon';
const ProxmoxServerNetwork = ({network, bridges}) => {

  const [interfaces, setInterfaces] = useState([]);
  const [nextId, setNextId] = useState(0);
  const [availableIds, setAvailableIds] = useState([]);

  useEffect(() => {
    if (network && network.length > 0) {
      network.forEach((net) => {
        console.log("****************8 net value", net);
        addInterface(null, net.value);
      });
    }
  }, [network]);

  const addInterface = (event, initialData = null ) => {
    if (event) event.preventDefault();
    const newId = availableIds.length > 0 ? availableIds[0] : nextId;
    const initData = initialData || {
      id: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][id]`, value: `net${newId}` },
      model: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][model]`, value: 'virtio' },
      bridge: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][bridge]`, value: bridges?.[0]?.iface || '' },
      tag: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][tag]`, value: '' },
      rate: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][rate]`, value: '' },
      queues: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][queues]`, value: '' },
      firewall: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][firewall]`, value: '0' },
      link_down: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][link_down]`, value: '0' },
    };

    setNextId(prevId => {
      const newNextId = prevId + 1;
      const newInterface = {
            id: newNextId,
            bridges: bridges,
            data: initData,
            networks: network,
        };
        setInterfaces(interfaces => [...interfaces, newInterface]);
        return newNextId;
      });
  };

  const removeInterface = (idToRemove) => {
    const newInterfaces = interfaces.filter(nic => nic.id !== idToRemove);
    setInterfaces(newInterfaces);
    setAvailableIds([...availableIds, idToRemove].sort((a, b) => a - b));
  };

  const updateNetworkData = (id, updatedData) => {
    setInterfaces(interfaces.map(net => net.id === id ? { ...net, data: updatedData } : net));
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
              onClick={() => removeInterface(nic.id)}
              variant="plain"
	      type="button"
          >
            <TimesIcon/>
          </button>
          </div>
          <NetworkInterface
              id={nic.id}
              data={nic.data}
              bridges={nic.bridges}
              networks={nic.networks}
	      updateNetworkData={updateNetworkData}
            />
        </div>
      ))}
      </PageSection>
    </div>
  );
};

export default ProxmoxServerNetwork;
