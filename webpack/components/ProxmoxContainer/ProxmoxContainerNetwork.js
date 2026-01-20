import React, { useState, useEffect, useCallback } from 'react';
import { Title, PageSection, Button } from '@patternfly/react-core';
import { TimesIcon } from '@patternfly/react-icons';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import PropTypes from 'prop-types';
import NetworkInterface from './components/NetworkInterface';

const ProxmoxContainerNetwork = ({ network, bridges, paramScope }) => {
  const [interfaces, setInterfaces] = useState([]);
  const [nextId, setNextId] = useState(0);
  const [availableIds, setAvailableIds] = useState([]);
  const [usedIds, setUsedIds] = useState(new Set());
  useEffect(() => {
    if (network?.length > 0) {
      const existingIds = new Set();
      network.forEach(net => {
        if (!net.value.name.value) return;
        const id = parseInt(net.value.id.value.replace('net', ''), 10);
        existingIds.add(id);
        addInterface(null, net.value);
      });
      setUsedIds(existingIds);
    }
  }, [network, addInterface]);

  const getLowestAvailableId = useCallback(() => {
    let id = 0;
    while (usedIds.has(id)) {
      id += 1;
    }
    return id;
  }, [usedIds]);

  const addInterface = useCallback(
    (event, initialData = null) => {
      if (event) event.preventDefault();
      const netId = getLowestAvailableId();
      const initData = initialData || {
        id: {
          name: `${paramScope}[interfaces_attributes][${nextId}][id]`,
          value: `net${netId}`,
        },
        name: {
          name: `${paramScope}[interfaces_attributes][${nextId}][name]`,
          value: `eth${netId}`,
        },
        bridge: {
          name: `${paramScope}[interfaces_attributes][${nextId}][bridge]`,
          value: bridges?.[0]?.iface || '',
        },
        dhcp: {
          name: `${paramScope}[interfaces_attributes][${nextId}][dhcp]`,
          value: '0',
        },
        cidr: {
          name: `${paramScope}[interfaces_attributes][${nextId}][cidr]`,
          value: '0',
        },
        gw: {
          name: `${paramScope}[interfaces_attributes][${nextId}][gw]`,
          value: '',
        },
        dhcp6: {
          name: `${paramScope}[interfaces_attributes][${nextId}][dhcp6]`,
          value: '0',
        },
        cidr6: {
          name: `${paramScope}[interfaces_attributes][${nextId}][cidr6]`,
          value: '0',
        },
        gw6: {
          name: `${paramScope}[interfaces_attributes][${nextId}][gw6]`,
          value: '',
        },
        tag: {
          name: `${paramScope}[interfaces_attributes][${nextId}][tag]`,
          value: '',
        },
        rate: {
          name: `${paramScope}[interfaces_attributes][${nextId}][rate]`,
          value: '',
        },
        firewall: {
          name: `${paramScope}[interfaces_attributes][${nextId}][firewall]`,
          value: '0',
        },
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
          bridges,
          data: initData,
          networks: network,
        };

        setInterfaces(prevInterfaces => [...prevInterfaces, newInterface]);
        return prevId;
      });
    },
    [availableIds, bridges, network, nextId, paramScope, getLowestAvailableId]
  );

  const removeInterface = idToRemove => {
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
    setInterfaces(
      interfaces.map(net =>
        net.id === id ? { ...net, data: updatedData } : net
      )
    );
  };

  return (
    <div>
      <PageSection padding={{ default: 'noPadding' }}>
        <Button
          ouiaId="proxmox-container-network-interface"
          onClick={addInterface}
          variant="secondary"
        >
          {__('Add Interface')}
        </Button>
        {interfaces.map(nic => (
          <div key={nic.id} style={{ position: 'relative' }}>
            <div
              style={{
                marginTop: '10px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <Title ouiaId="proxmox-container-network-nic" headingLevel="h4">
                {sprintf(__('Nic %(nicId)s'), { nicId: nic.id })}
              </Title>
              <button onClick={() => removeInterface(nic.id)} type="button">
                <TimesIcon />
              </button>
            </div>
            <NetworkInterface
              id={nic.id}
              data={nic.data}
              bridges={nic.bridges}
              networks={nic.networks}
              updateNetworkData={updateNetworkData}
              existingInterfaces={interfaces}
            />
          </div>
        ))}
      </PageSection>
    </div>
  );
};

ProxmoxContainerNetwork.propTypes = {
  network: PropTypes.array,
  bridges: PropTypes.array,
  paramScope: PropTypes.string,
};

ProxmoxContainerNetwork.defaultProps = {
  network: [],
  bridges: [],
  paramScope: '',
};

export default ProxmoxContainerNetwork;
