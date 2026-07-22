import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';
import { Spinner } from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import { createStoragesMap, imagesByStorage } from '../ProxmoxStoragesUtils';
import ProxmoxComputeSelectors from '../ProxmoxComputeSelectors';
import InputField from '../common/FormInputs';
import useVolumes from '../hooks/useVolumes';

const ProxmoxContainerOptions = ({
  options,
  storages,
  nodeId,
  computeResourceId,
  newVm,
  fromProfile,
}) => {
  const [opts, setOpts] = useState(options);
  const storagesMap = createStoragesMap(storages, 'vztmpl', nodeId);

  const storageValue = opts?.ostemplateStorage?.value || 'local';
  const isEditMode = !newVm && !fromProfile;

  const fromStorages = useMemo(
    () => imagesByStorage(storages, nodeId, storageValue, 'vztmpl'),
    [storages, nodeId, storageValue]
  );

  const shouldFetchFromAPI =
    !isEditMode &&
    fromStorages.length === 0 &&
    computeResourceId &&
    nodeId &&
    storageValue;
  const { volumes, loadingVolumes, volumeError } = useVolumes(
    shouldFetchFromAPI ? computeResourceId : null,
    shouldFetchFromAPI ? nodeId : null,
    shouldFetchFromAPI ? storageValue : null,
    'vztmpl'
  );

  const volumesMap = useMemo(() => {
    if (fromStorages.length > 0) {
      return fromStorages;
    }

    if (volumes.length === 0) {
      return [{ value: '', label: '' }];
    }

    const mapped = volumes
      .sort((a, b) => (a?.volid || '').localeCompare(b?.volid || ''))
      .map(v => ({ value: v.volid, label: v.volid }));

    return [{ value: '', label: '' }, ...mapped];
  }, [fromStorages, volumes]);

  const handleChange = e => {
    const { name, type, checked, value: targetValue } = e.target;
    let value;
    if (type === 'checkbox') {
      value = checked ? '1' : '0';
    } else {
      value = targetValue;
    }

    const updatedKey = Object.keys(opts).find(key => opts[key].name === name);
    if (!updatedKey) return;

    setOpts(prev => {
      const next = {
        ...prev,
        [updatedKey]: { ...prev[updatedKey], value },
      };
      if (updatedKey === 'ostemplateStorage') {
        next.ostemplateFile = { ...next.ostemplateFile, value: '' };
      }

      return next;
    });
  };

  return (
    <div>
      <InputField
        name={opts?.ostemplateStorage?.name}
        label={__('Template Storage')}
        value={opts?.ostemplateStorage?.value}
        options={storagesMap}
        type="select"
        onChange={handleChange}
      />

      {loadingVolumes ? (
        <div
          style={{
            display: 'flex',
            justifyContent: 'center',
            gap: '0.5rem',
            padding: '0.5rem 0',
          }}
        >
          <Spinner size="md" />
          <span>{__('Fetching templates...')}</span>
        </div>
      ) : (
        <InputField
          name={opts?.ostemplateFile?.name}
          label={__('OS Template')}
          required
          options={volumesMap}
          value={opts?.ostemplateFile?.value}
          type="select"
          disabled={isEditMode}
          onChange={handleChange}
          error={
            volumeError ? __('Failed fetching templates please try again.') : ''
          }
        />
      )}

      <InputField
        name={opts?.password?.name}
        label={__('Root Password')}
        required
        type="password"
        value={opts?.password?.value}
        onChange={handleChange}
      />
      <InputField
        name={opts?.onboot?.name}
        label={__('Start at boot')}
        type="checkbox"
        value={opts?.onboot?.value}
        checked={String(opts?.onboot?.value) === '1'}
        onChange={handleChange}
      />
      <InputField
        name={opts?.ostype?.name}
        label={__('OS Type')}
        type="select"
        options={ProxmoxComputeSelectors.proxmoxOstypesMap}
        value={opts?.ostype?.value}
        onChange={handleChange}
      />
      <InputField
        name={opts?.hostname?.name}
        label={__('Hostname')}
        value={opts?.hostname?.value}
        disabled
        onChange={handleChange}
      />
      <InputField
        name={opts?.nameserver?.name}
        label={__('DNS server')}
        value={opts?.nameserver?.value}
        onChange={handleChange}
      />
      <InputField
        name={opts?.searchdomain?.name}
        label={__('Search Domain')}
        value={opts?.searchdomain?.value}
        onChange={handleChange}
      />
      <InputField
        name={opts?.featureNesting?.name}
        label={__('Feature: nesting')}
        info={__(
          'Allow nested virtualization / running containers inside the container.'
        )}
        type="checkbox"
        value={opts?.featureNesting?.value}
        checked={String(opts?.featureNesting?.value) === '1'}
        onChange={handleChange}
      />
      <InputField
        name={opts?.featureKeyctl?.name}
        label={__('Feature: keyctl')}
        info={__(
          'Enable the keyctl() system call (needed by some workloads, e.g. systemd).'
        )}
        type="checkbox"
        value={opts?.featureKeyctl?.value}
        checked={String(opts?.featureKeyctl?.value) === '1'}
        onChange={handleChange}
      />
      <InputField
        name={opts?.featureFuse?.name}
        label={__('Feature: FUSE')}
        info={__('Allow using FUSE file systems inside the container.')}
        type="checkbox"
        value={opts?.featureFuse?.value}
        checked={String(opts?.featureFuse?.value) === '1'}
        onChange={handleChange}
      />
      <InputField
        name={opts?.featureMount?.name}
        label={__('Feature: mount')}
        info={__(
          'Semicolon-separated list of file systems allowed to be mounted, e.g. nfs;cifs.'
        )}
        value={opts?.featureMount?.value}
        onChange={handleChange}
      />
    </div>
  );
};

ProxmoxContainerOptions.propTypes = {
  options: PropTypes.object,
  storages: PropTypes.array,
  nodeId: PropTypes.string,
  computeResourceId: PropTypes.number,
  newVm: PropTypes.bool,
  fromProfile: PropTypes.bool,
};

ProxmoxContainerOptions.defaultProps = {
  options: {},
  storages: [],
  nodeId: '',
  computeResourceId: null,
  newVm: false,
  fromProfile: false,
};

export default ProxmoxContainerOptions;
