import React, { useEffect, useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import {
  Title,
  Divider,
  PageSection,
  Radio,
  Spinner,
  FormHelperText,
  HelperText,
  HelperTextItem,
} from '@patternfly/react-core';
import { TimesIcon } from '@patternfly/react-icons';
import { translate as __ } from 'foremanReact/common/I18n';
import { createStoragesMap } from '../../ProxmoxStoragesUtils';
import InputField from '../../common/FormInputs';
import useVolumes from '../../hooks/useVolumes';

const CDRom = ({
  onRemove,
  data,
  storages,
  nodeId,
  computeResourceId,
  canAttachCdromImage,
}) => {
  const [cdrom, setCdrom] = useState(data);

  const storagesMap = useMemo(
    () => createStoragesMap(storages, 'iso', nodeId),
    [storages, nodeId]
  );

  const mediaValue = cdrom?.cdrom?.value;
  const normalizedMediaValue = mediaValue === 'cdrom' ? 'physical' : mediaValue;
  const storageValue = cdrom?.storage?.value || '';

  const shouldFetch =
    normalizedMediaValue === 'image' &&
    computeResourceId &&
    nodeId &&
    storageValue;
  const { volumes, loadingVolumes, volumeError } = useVolumes(
    shouldFetch ? computeResourceId : null,
    shouldFetch ? nodeId : null,
    shouldFetch ? storageValue : null
  );

  const handleMediaChange = (_, e) => {
    const media = e.target.value;
    setCdrom(prev => ({
      ...prev,
      cdrom: { ...prev.cdrom, value: media },
      ...(media !== 'image' ? { volid: { ...prev.volid, value: '' } } : {}),
    }));
  };

  const handleChange = e => {
    const { name, type, checked, value: targetValue } = e.target;
    let value;
    if (type === 'checkbox') {
      value = checked ? '1' : '0';
    } else {
      value = targetValue;
    }

    const updatedKey = Object.keys(cdrom).find(key => cdrom[key].name === name);
    if (!updatedKey) return;

    setCdrom(prev => {
      const next = {
        ...prev,
        [updatedKey]: { ...prev[updatedKey], value },
      };

      if (updatedKey === 'storage') {
        next.volid = { ...next.volid, value: '' };
      }

      return next;
    });
  };

  useEffect(() => {
    if (normalizedMediaValue !== 'image') return;
    if (storageValue) return;
    if (!storagesMap?.length) return;

    const first = storagesMap[0]?.value || '';
    if (!first) return;

    setCdrom(prev => ({
      ...prev,
      storage: { ...prev.storage, value: first },
      volid: { ...prev.volid, value: '' },
    }));
  }, [normalizedMediaValue, storageValue, storagesMap]);

  const imagesMap = useMemo(
    () => [
      { value: '', label: '' },
      ...volumes
        .filter(v => v.content === 'iso')
        .map(v => ({ value: v.volid, label: v.volid })),
    ],
    [volumes]
  );

  return (
    <div style={{ position: 'relative' }}>
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <Title ouiaId="proxmox-server-cdrom-title" headingLevel="h4">
          {__('CD-ROM')}
        </Title>
        <button onClick={onRemove} type="button">
          <TimesIcon />
        </button>
      </div>

      <Divider component="li" style={{ marginBottom: '1rem' }} />

      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
        }}
      >
        <Title ouiaId="proxmox-server-cdrom-media-title" headingLevel="h5">
          {__('Media')}
        </Title>
      </div>

      <Divider component="li" style={{ marginBottom: '1rem' }} />

      <div style={{ display: 'flex', gap: '1rem' }}>
        <Radio
          ouiaId="proxmox-server-cdrom-media-none"
          id="radio-none"
          name={cdrom?.cdrom?.name}
          label={__('None')}
          value="none"
          isChecked={normalizedMediaValue === 'none'}
          onChange={(e, _) => handleMediaChange(_, e)}
        />
        <Radio
          ouiaId="proxmox-server-cdrom-media-physical"
          id="radio-physical"
          name={cdrom?.cdrom?.name}
          label={__('Physical')}
          value="physical"
          isChecked={normalizedMediaValue === 'physical'}
          onChange={(e, _) => handleMediaChange(_, e)}
        />
        <Radio
          ouiaId="proxmox-server-cdrom-media-image"
          id="radio-image"
          name={cdrom?.cdrom?.name}
          label={__('Image')}
          value="image"
          isChecked={normalizedMediaValue === 'image'}
          onChange={(e, _) => handleMediaChange(_, e)}
          isDisabled={!canAttachCdromImage}
        />
      </div>

      {!canAttachCdromImage && (
        <FormHelperText>
          <HelperText id="helper-cdrom-image-permission">
            <HelperTextItem variant="warning">
              {__(
                'You are not authorized to attach or change CD-ROM ISO images'
              )}
            </HelperTextItem>
          </HelperText>
        </FormHelperText>
      )}

      {normalizedMediaValue === 'image' && (
        <PageSection padding={{ default: 'noPadding' }}>
          <Title ouiaId="proxmox-server-cdrom-image-title" headingLevel="h5">
            {__('Image')}
          </Title>
          <Divider component="li" style={{ marginBottom: '2rem' }} />

          <InputField
            label={__('Storage')}
            name={cdrom?.storage?.name}
            type="select"
            value={
              cdrom?.storage?.value ||
              (storagesMap?.length > 0 ? storagesMap[0].value : '')
            }
            options={storagesMap}
            onChange={handleChange}
            disabled={!canAttachCdromImage}
          />

          {loadingVolumes ? (
            <div
              style={{
                display: 'flex',
                justifyContent: 'center',
                gap: '0.5rem',
              }}
            >
              <Spinner size="md" />
              <span>{__('Fetching images ISO...')}</span>
            </div>
          ) : (
            <InputField
              name={cdrom?.volid?.name}
              label={__('Image ISO')}
              type="select"
              value={cdrom?.volid?.value}
              options={imagesMap}
              onChange={handleChange}
              disabled={!canAttachCdromImage}
              error={
                volumeError
                  ? __('Failed fetching images ISO please try again.')
                  : ''
              }
            />
          )}
        </PageSection>
      )}
    </div>
  );
};

CDRom.propTypes = {
  onRemove: PropTypes.func.isRequired,
  data: PropTypes.shape({
    cdrom: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string.isRequired,
    }).isRequired,
    storage: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string,
    }).isRequired,
    volid: PropTypes.shape({
      name: PropTypes.string.isRequired,
      value: PropTypes.string,
    }).isRequired,
    storageType: PropTypes.shape({
      name: PropTypes.string.isRequired,
    }).isRequired,
  }).isRequired,
  storages: PropTypes.array.isRequired,
  nodeId: PropTypes.string.isRequired,
  computeResourceId: PropTypes.number.isRequired,
  canAttachCdromImage: PropTypes.bool.isRequired,
};

export default CDRom;
