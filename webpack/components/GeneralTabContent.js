import React from 'react';
import PropTypes from 'prop-types';
import { PageSection, Divider } from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';
import InputField from './common/FormInputs';
import { createStoragesMap } from './ProxmoxStoragesUtils';

const GeneralTabContent = ({
  general,
  fromProfile,
  newVm,
  nodesMap,
  poolsMap,
  imagesMap,
  storages,
  provisionMethod,
  handleChange,
  untemplatable,
}) => {
  const isoStorages = createStoragesMap(
    storages,
    'iso',
    general?.nodeId?.value
  );
  const hasIsoStorages = isoStorages.length > 0;
  const usesIsoUploadStorage = ['bootdisk', 'image'].includes(provisionMethod);

  return (
    <PageSection padding={{ default: 'noPadding' }}>
      <Divider component="li" style={{ marginBottom: '2rem' }} />
      <InputField
        name={general?.vmid?.name}
        label={__('VM ID')}
        required
        type="number"
        value={general?.vmid?.value}
        disabled={!newVm || fromProfile}
        onChange={handleChange}
      />
      <InputField
        name={general?.nodeId?.name}
        label={__('Node')}
        required
        type="select"
        value={general?.nodeId?.value}
        options={nodesMap}
        onChange={handleChange}
      />
      <InputField
        name={general?.pool?.name}
        label={__('Pool')}
        type="select"
        value={general?.pool?.value}
        options={poolsMap}
        onChange={handleChange}
      />
      {(newVm || fromProfile) && general?.type?.value === 'qemu' && (
        <InputField
          name={general?.isoUploadStorage?.name}
          label={__('ISO Upload Storage')}
          info={__(
            'Storage used for ISO uploads when using Bootdisk provisioning or image-based provisioning with user data.'
          )}
          required={newVm && usesIsoUploadStorage}
          type="select"
          value={general?.isoUploadStorage?.value || ''}
          options={[{ value: '', label: '' }, ...isoStorages]}
          disabled={(!fromProfile && !usesIsoUploadStorage) || !hasIsoStorages}
          error={
            usesIsoUploadStorage && !hasIsoStorages
              ? __(
                  'No ISO storage is available for the selected node. Try selecting another node.'
                )
              : ''
          }
          onChange={handleChange}
        />
      )}
      {newVm && !fromProfile && (
        <InputField
          name={general?.startAfterCreate?.name}
          label={__('Start after creation?')}
          type="checkbox"
          value={general?.startAfterCreate?.value}
          checked={String(general?.startAfterCreate?.value) === '1'}
          onChange={handleChange}
        />
      )}
      {!fromProfile && !untemplatable && (
        <InputField
          name={general?.templated?.name}
          label={__('Create image?')}
          type="checkbox"
          value={general?.templated?.value}
          checked={String(general?.templated?.value) === '1'}
          disabled={untemplatable}
          onChange={handleChange}
        />
      )}
      {fromProfile && (
        <InputField
          name={general?.imageId?.name}
          label={__('Image')}
          type="select"
          value={general?.imageId?.value}
          disabled={imagesMap.length === 0}
          options={imagesMap}
          onChange={handleChange}
        />
      )}
      <InputField
        name={general?.description?.name}
        label={__('Description')}
        type="textarea"
        value={general?.description?.value}
        onChange={handleChange}
      />
    </PageSection>
  );
};
GeneralTabContent.propTypes = {
  general: PropTypes.object.isRequired,
  fromProfile: PropTypes.bool,
  newVm: PropTypes.bool,
  nodesMap: PropTypes.array,
  poolsMap: PropTypes.array,
  imagesMap: PropTypes.array,
  storages: PropTypes.array,
  provisionMethod: PropTypes.string,
  handleChange: PropTypes.func.isRequired,
  untemplatable: PropTypes.bool,
};

GeneralTabContent.defaultProps = {
  fromProfile: false,
  newVm: false,
  nodesMap: [],
  poolsMap: [],
  imagesMap: [],
  storages: [],
  provisionMethod: 'build',
  untemplatable: false,
};

export default GeneralTabContent;
