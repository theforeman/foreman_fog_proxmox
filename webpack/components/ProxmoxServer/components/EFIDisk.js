import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  FormHelperText,
  HelperText,
  HelperTextItem,
  PageSection,
} from '@patternfly/react-core';
import { TimesIcon } from '@patternfly/react-icons';
import { translate as __ } from 'foremanReact/common/I18n';
import { createStoragesMap } from '../../ProxmoxStoragesUtils';
import { setEfiDiskVolId } from '../../ProxmoxVmUtils';
import InputField from '../../common/FormInputs';
import { useBios } from '../../ProxmoxBiosContext';

const EFIDisk = ({ onRemove, data, storages, nodeId, vmId }) => {
  const [efidisk, setEfiDisk] = useState(data);
  const storagesMap = createStoragesMap(storages, null, nodeId);
  const { bios } = useBios();
  const isBiosOvmf = bios === 'ovmf';

  useEffect(() => {
    if (storagesMap?.length > 0 && !efidisk?.volid?.value) {
      const firstStorage = storagesMap[0].value;

      const newVolId = setEfiDiskVolId(null, firstStorage, vmId);

      setEfiDisk(prev => ({
        ...prev,
        storage: {
          ...prev.storage,
          value: firstStorage,
        },
        volid: {
          ...prev.volid,
          value: newVolId,
        },
      }));
    }
  }, [storagesMap, efidisk, vmId]);

  const handleChange = e => {
    const { name, type, checked, value: targetValue } = e.target;
    let value;
    if (type === 'checkbox') {
      value = checked ? '1' : '0';
    } else {
      value = targetValue;
    }

    const updatedKey = Object.keys(efidisk).find(
      key => efidisk[key].name === name
    );
    let updatedData = {
      ...efidisk,
      [updatedKey]: { ...efidisk[updatedKey], value },
    };

    // If storage is changed, update volid accordingly
    if (name === efidisk?.storage?.name) {
      const newVolId = setEfiDiskVolId(null, value, vmId);
      updatedData = {
        ...updatedData,
        volid: {
          ...updatedData.volid,
          value: newVolId,
        },
      };
    }

    setEfiDisk(updatedData);
  };

  return (
    <div style={{ position: 'relative' }}>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <Title ouiaId="proxmox-server-efidisk-title" headingLevel="h4">
          {__('EFI Disk')}
          {!isBiosOvmf && (
            <FormHelperText>
              <HelperText id="helper-bios">
                <HelperTextItem variant="warning">
                  {__(
                    'The EFI Disk requires OVMF BIOS. Please switch the BIOS type to OVMF.'
                  )}
                </HelperTextItem>
              </HelperText>
            </FormHelperText>
          )}
        </Title>
        <button onClick={onRemove}>
          <TimesIcon />
        </button>
      </div>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      />
      <PageSection padding={{ default: 'noPadding' }}>
        <Divider component="li" style={{ marginBottom: '2rem' }} />
        <input
          name={efidisk?.id?.name}
          type="hidden"
          value={efidisk?.id.value}
        />
        <input
          name={efidisk?.volid?.name}
          type="hidden"
          value={efidisk?.volid.value}
        />
        <input
          name={efidisk?.format?.name}
          type="hidden"
          value={efidisk?.format.value}
        />
        <InputField
          label={__('EFI Storage')}
          name={efidisk?.storage?.name}
          type="select"
          value={
            efidisk?.storage?.value ||
            (storagesMap?.length > 0 ? storagesMap[0].value : '')
          }
          options={storagesMap}
          onChange={handleChange}
        />
        <InputField
          name={efidisk?.preEnrolledKeys?.name}
          label={__('Pre-Enrolled Keys')}
          type="checkbox"
          value={efidisk?.preEnrolledKeys?.value}
          checked={String(efidisk?.preEnrolledKeys?.value) === '1'}
          onChange={handleChange}
        />
      </PageSection>
    </div>
  );
};

EFIDisk.propTypes = {
  onRemove: PropTypes.func.isRequired,
  data: PropTypes.shape({
    id: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.number.isRequired,
    }).isRequired,
    storage: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string,
    }).isRequired,
    format: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string,
    }).isRequired,
    preEnrolledKeys: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string,
    }).isRequired,
    volid: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string.isRequired,
    }).isRequired,
  }).isRequired,
  storages: PropTypes.array.isRequired,
  nodeId: PropTypes.string.isRequired,
  vmId: PropTypes.string.isRequired,
};

export default EFIDisk;
