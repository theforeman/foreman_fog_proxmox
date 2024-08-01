import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import { Divider } from '@patternfly/react-core';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import InputField from '../../common/FormInputs';
import ProxmoxComputeSelectors from '../../ProxmoxComputeSelectors';
import { createStoragesMap } from '../../ProxmoxStoragesUtils';

const HardDisk = ({
  id,
  data,
  storages,
  disks,
  updateHardDiskData,
  createUniqueDevice,
  nodeId,
}) => {
  const [hdd, setHdd] = useState(data);
  const [error, setError] = useState(null);
  const storagesMap = createStoragesMap(storages, null, nodeId);
  useEffect(() => {
    const currentHddData = JSON.stringify(hdd);
    const parentHddData = JSON.stringify(data);

    if (currentHddData !== parentHddData) {
      updateHardDiskData(id, hdd);
    }
  }, [hdd, id, data, updateHardDiskData]);
  const handleChange = e => {
    const { name, value } = e.target;
    const updatedKey = Object.keys(hdd).find(key => hdd[key].name === name);

    if (updatedKey === 'controller') {
      const updatedDeviceInfo = createUniqueDevice('hard_disk', value);
      if (updatedDeviceInfo) {
        setHdd({
          ...hdd,
          controller: { ...hdd.controller, value },
          device: { ...hdd.device, value: updatedDeviceInfo.device },
          id: { ...hdd.id, value: updatedDeviceInfo.id },
        });
        setError(null);
      } else {
        setError(
          sprintf(
            __(
              'Reached maximum number of devices for controller %(value)s. Please select another controller.'
            ),
            { value }
          )
        );
        setHdd({
          ...hdd,
          controller: { ...hdd.controller, value },
          device: { ...hdd.device, value: '' },
          id: { ...hdd.id, value: '' },
        });
      }
    } else {
      const updatedData = {
        ...hdd,
        [updatedKey]: { ...hdd[updatedKey], value },
      };
      setHdd(updatedData);
    }
  };
  return (
    <div>
      <Divider component="li" style={{ marginBottom: '2rem' }} />
      <input
        name={hdd?.storageType?.name}
        type="hidden"
        value={hdd?.storageType?.value}
        onChange={handleChange}
      />
      <input
        name={hdd?.id?.name}
        type="hidden"
        value={hdd?.id?.value}
        onChange={handleChange}
      />
      <input
        name={hdd?.volid?.name}
        type="hidden"
        value={hdd?.volid?.value}
        onChange={handleChange}
      />
      <InputField
        name={hdd?.storage?.name}
        label={__('Storage')}
        type="select"
        value={hdd?.storage?.value}
        options={storagesMap}
        onChange={handleChange}
      />
      <InputField
        name={hdd?.controller?.name}
        label={__('Controller')}
        type="select"
        value={hdd?.controller?.value}
        options={ProxmoxComputeSelectors.proxmoxControllersHDDMap}
        onChange={handleChange}
        error={error}
      />
      <InputField
        label={__('Device')}
        name={hdd?.device?.name}
        value={hdd?.device?.value}
        onChange={handleChange}
        disabled
        tooltip={__('Device value is set automatically.')}
      />
      <InputField
        name={hdd?.cache?.name}
        label={__('Cache')}
        type="select"
        value={hdd?.cache?.value}
        options={ProxmoxComputeSelectors.proxmoxCachesMap}
        onChange={handleChange}
      />
      <InputField
        name={hdd?.size?.name}
        label={__('Size')}
        type="number"
        value={hdd?.size?.value}
        onChange={handleChange}
      />
    </div>
  );
};

HardDisk.propTypes = {
  id: PropTypes.number.isRequired,
  data: PropTypes.object,
  storages: PropTypes.array,
  disks: PropTypes.array,
  updateHardDiskData: PropTypes.func,
  createUniqueDevice: PropTypes.func,
  nodeId: PropTypes.string,
};

HardDisk.defaultProps = {
  data: {},
  storages: [],
  disks: [],
  nodeId: '',
  updateHardDiskData: Function.prototype,
  createUniqueDevice: Function.prototype,
};

export default HardDisk;
