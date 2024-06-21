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
  const [usedIds, setUsedIds] = useState(new Set());

  useEffect(() => {
    if (network && network.length > 0) {
      const existingIds = new Set();
      network.forEach((net) => {
        if (!net.value.name.value) return;  
	const id = parseInt(net.value.id.value.replace('net', ''), 10);
        existingIds.add(id);
        console.log("****************8 net value", net);
        addInterface(null, net.value);
      });
      setUsedIds(existingIds);
    }
  }, [network]);

  const getLowestAvailableId = () => {
    let id = 0;
    while (usedIds.has(id)) {
      id += 1;
    }
    return id;
  };

  const addInterface = (event, initialData = null ) => {
    if (event) event.preventDefault();
    const netId = getLowestAvailableId();
    const initData = initialData || {
      id: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][id]`, value: `net${netId}` },
      name: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][name]`, value: `eth${netId}` },
      bridge: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][bridge]`, value: bridges?.[0]?.iface || '' },
      dhcp: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][dhcp]`, value: '0' },
      cidr: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][cidr]`, value: '' },
      gw: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][gw]`, value: '' },
      dhcp6: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][dhcp6]`, value: '0' },
      cidr6: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][cidr6]`, value: '' },
      gw6: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][gw6]`, value: '' },
      tag: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][tag]`, value: '' },
      rate: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][rate]`, value: '' },
      firewall: { name: `compute_attribute[vm_attrs][interfaces_attributes][${nextId}][firewall]`, value: '0' },
    };
    setNextId(prevId => {
      if (availableIds.length > 0) {
        setAvailableIds(availableIds.slice(1));
      } else {
        prevId += 1;
      }
      setUsedIds(prevIds => new Set(prevIds).add(netId));
      const newId = availableIds.length > 0 ? availableIds[0] : prevId;
      const newInterface = {
        id: newId,
        bridges: bridges,
        data: initData,
        networks: network,
      };

      setInterfaces(interfaces => [...interfaces, newInterface]);
      return prevId;
    });
  };

  const removeInterface = (idToRemove) => {
    const newInterfaces = interfaces.filter(nic => nic.id !== idToRemove);
    setInterfaces(newInterfaces);
    setAvailableIds([...availableIds, idToRemove].sort((a, b) => a - b));
    setUsedIds(prevIds => {
      const newIds = new Set(prevIds);
      newIds.delete(idToRemove);
      return newIds;
    });
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

export default ProxmoxContainerNetwork;
