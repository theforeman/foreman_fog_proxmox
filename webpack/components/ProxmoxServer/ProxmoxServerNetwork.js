import React, { useState, useEffect, useCallback } from 'react';
import { Title, PageSection, Button } from '@patternfly/react-core';
import { TimesIcon } from '@patternfly/react-icons';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import PropTypes from 'prop-types';
import NetworkInterface from './components/NetworkInterface';

const ProxmoxServerNetwork = ({ network, bridges, paramScope }) => {
  const [interfaces, setInterfaces] = useState([]);
  const [nextId, setNextId] = useState(0);
  const [availableIds, setAvailableIds] = useState([]);
  const [usedIds, setUsedIds] = useState(new Set());
  useEffect(() => {
    if (network?.length > 0) {
      const existingIds = new Set();
      network.forEach(net => {
        if (!net.value.model.value) return;
        const id = parseInt(net.value.id.value.replace('net', ''), 10);
        existingIds.add(id);
        addInterface(null, net.value);
      });
      setUsedIds(existingIds);
    }
  }, [network]);

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
        model: {
          name: `${paramScope}[interfaces_attributes][${nextId}][model]`,
          value: 'virtio',
        },
        bridge: {
          name: `${paramScope}[interfaces_attributes][${nextId}][bridge]`,
          value: bridges?.[0]?.iface || '',
        },
        tag: {
          name: `${paramScope}[interfaces_attributes][${nextId}][tag]`,
          value: '',
        },
        rate: {
          name: `${paramScope}[interfaces_attributes][${nextId}][rate]`,
          value: '',
        },
        queues: {
          name: `${paramScope}[interfaces_attributes][${nextId}][queues]`,
          value: '',
        },
        firewall: {
          name: `${paramScope}[interfaces_attributes][${nextId}][firewall]`,
          value: '0',
        },
        linkDown: {
          name: `${paramScope}[interfaces_attributes][${nextId}][link_down]`,
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
          data: initData,
          networks: network,
        };

        setInterfaces(prevInterfaces => [...prevInterfaces, newInterface]);
        return prevId;
      });
    },
    [bridges, network, paramScope, availableIds, nextId, getLowestAvailableId]
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
          ouiaId="proxmox-server-network-interface"
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
              <Title ouiaId="proxmox-server-network-nic" headingLevel="h4">
                {sprintf(__('Nic %(nicId)s'), { nicId: nic.id })}
              </Title>
              <button onClick={() => removeInterface(nic.id)} type="button">
                <TimesIcon />
              </button>
            </div>
            <NetworkInterface
              id={nic.id}
              data={nic.data}
              bridges={bridges}
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

ProxmoxServerNetwork.propTypes = {
  network: PropTypes.object,
  bridges: PropTypes.array,
  paramScope: PropTypes.string,
};

ProxmoxServerNetwork.defaultProps = {
  network: {},
  bridges: [],
  paramScope: '',
};

export default ProxmoxServerNetwork;
