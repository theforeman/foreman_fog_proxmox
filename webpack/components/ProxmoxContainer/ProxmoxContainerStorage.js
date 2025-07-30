import React, { useState, useEffect, useCallback } from 'react';
import { Button, Title, Divider, PageSection } from '@patternfly/react-core';
import { TimesIcon } from '@patternfly/react-icons';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import PropTypes from 'prop-types';
import { createStoragesMap } from '../ProxmoxStoragesUtils';
import InputField from '../common/FormInputs';
import MountPoint from './MountPoint';

const ProxmoxContainerStorage = ({ storage, storages, nodeId, paramScope }) => {
  const initData = {
    id: {
      name: `${paramScope}[volumes_attributes][0][id]`,
      value: 'rootfs',
    },
    device: {
      name: `${paramScope}[volumes_attributes][0][device]`,
      value: '8',
    },
    storage: {
      name: `${paramScope}[volumes_attributes][0][storage]`,
      value: '',
    },
    size: {
      name: `${paramScope}[volumes_attributes][0][size]`,
      value: 8,
    },
    volid: {
      name: `${paramScope}[volumes_attributes][0][volid]`,
      value: null,
    },
  };
  const [rootfs, setRootfs] = useState(initData);
  useEffect(() => {
    if (storage && storage.length > 0) {
      storage.forEach(disk => {
        if (disk.name === 'rootfs') {
          setRootfs(disk.value);
        }
        if (disk.name === 'mount_point') {
          addMountPoint(null, disk.value);
        }
      });
    }
  }, [storage]);

  const handleChange = e => {
    const { name, value } = e.target;
    const updatedKey = Object.keys(rootfs).find(
      key => rootfs[key].name === name
    );
    const updatedData = {
      ...rootfs,
      [updatedKey]: { ...rootfs[updatedKey], value },
    };
    setRootfs(updatedData);
  };
  const [mountPoints, setMountPoints] = useState([]);
  const [nextId, setNextId] = useState(0);
  const storagesMap = createStoragesMap(storages, null, nodeId);
  const addMountPoint = useCallback(
    (event, initialData = null) => {
      if (event) event.preventDefault();
      const initMP = initialData || {
        id: {
          name: `${paramScope}[volumes_attributes][${nextId}][id]`,
          value: `mp${nextId}`,
        },
        device: {
          name: `${paramScope}[volumes_attributes][${nextId}][device]`,
          value: `${nextId}`,
        },
        storage: {
          name: `${paramScope}[volumes_attributes][${nextId}][storage]`,
          value: '',
        },
        size: {
          name: `${paramScope}[volumes_attributes][${nextId}][size]`,
          value: 8,
        },
        mp: {
          name: `${paramScope}[volumes_attributes][${nextId}][mp]`,
          value: '',
        },
        volid: {
          name: `${paramScope}[volumes_attributes][${nextId}][volid]`,
          value: null,
        },
      };

      setNextId(prevNextId => {
        const newNextId = prevNextId + 1;
        const newMountPoint = {
          id: newNextId,
          data: initMP,
          storagesMap,
        };
        setMountPoints(prevMountPoints => [...prevMountPoints, newMountPoint]);
        return newNextId;
      });
    },
    [nextId, paramScope, setMountPoints, setNextId, storagesMap]
  );

  const removeMountPoint = idToRemove => {
    const newMountPoints = mountPoints.filter(
      mountPoint => mountPoint.props.id !== idToRemove
    );
    setMountPoints(newMountPoints);
  };

  return (
    <div>
      <PageSection padding={{ default: 'noPadding' }}>
        <Title ouiaId="proxmox-container-storage-rootfs" headingLevel="h3">
          {__('Rootfs')}
        </Title>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <InputField
          name={rootfs?.storage?.name}
          label="Storage"
          type="select"
          value={rootfs?.storage?.value}
          options={storagesMap}
          onChange={handleChange}
        />
        <InputField
          name={rootfs?.size?.name}
          label={__('Size (GB)')}
          type="number"
          value={rootfs?.size?.value}
          onChange={handleChange}
        />
        <input
          name={rootfs?.id?.name}
          type="hidden"
          value={rootfs?.id?.value || 'rootfs'}
          onChange={handleChange}
        />
        <input
          name={rootfs?.volid?.name}
          type="hidden"
          value={rootfs?.volid?.value}
        />
      </PageSection>
      <PageSection padding={{ default: 'noPadding' }}>
        <Title ouiaId="proxmox-container-storage-title" headingLevel="h3">
          Storage
        </Title>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <Button
          ouiaId="proxmox-container-storage-mountpoint-button"
          onClick={addMountPoint}
          variant="secondary"
        >
          {__('Add MountPoint')}
        </Button>
        {mountPoints.map(mountPoint => (
          <div key={mountPoint.id} style={{ position: 'relative' }}>
            <div
              style={{
                marginTop: '10px',
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
              }}
            >
              <Title
                ouiaId="proxmox-container-storage-mountpoint-title"
                headingLevel="h4"
              >
                {sprintf(__('Mount Point %(mp)s'), { mp: mountPoint.id })}
              </Title>
              <button onClick={() => removeMountPoint(mountPoint.id)}>
                <TimesIcon />
              </button>
            </div>
            <MountPoint
              key={mountPoint.id}
              id={mountPoint.id}
              data={mountPoint.data}
              storagesMap={mountPoint.storagesMap}
            />
          </div>
        ))}
      </PageSection>
    </div>
  );
};

ProxmoxContainerStorage.propTypes = {
  storage: PropTypes.object,
  storages: PropTypes.array,
  nodeId: PropTypes.string,
  paramScope: PropTypes.string,
};

ProxmoxContainerStorage.defaultProps = {
  storage: {},
  storages: [],
  nodeId: '',
  paramScope: '',
};

export default ProxmoxContainerStorage;
