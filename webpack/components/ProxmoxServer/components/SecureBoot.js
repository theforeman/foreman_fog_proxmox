import React from 'react';
import PropTypes from 'prop-types';
import {
  FormHelperText,
  HelperText,
  HelperTextItem,
} from '@patternfly/react-core';
import { translate as __ } from 'foremanReact/common/I18n';

export const secureBootSelected = options =>
  options?.bios?.value === 'uefi_secure_boot' ||
  (options?.bios?.value === 'ovmf' &&
    (String(options?.isSecureBoot?.value) === '1' ||
      String(options?.efidisk?.preEnrolledKeys?.value) === '1'));

export const normalizeFirmwareOptions = options => {
  const isSecureBootSelected = secureBootSelected(options);

  return {
    ...options,
    bios: {
      ...options?.bios,
      value: isSecureBootSelected ? 'uefi_secure_boot' : options?.bios?.value,
    },
    isSecureBoot: {
      ...options?.isSecureBoot,
      value: isSecureBootSelected ? '1' : '0',
    },
  };
};

const SecureBoot = ({ bios, isSecureBoot, efiDiskSelected }) => (
  <>
    {bios?.value === 'uefi_secure_boot' && !efiDiskSelected && (
      <div className="form-group">
        <div className="col-md-offset-2 col-md-6">
          <FormHelperText>
            <HelperText id="helper-secure-boot-efidisk">
              <HelperTextItem variant="warning">
                {__('Please make sure that an EFI disk is selected.')}
              </HelperTextItem>
            </HelperText>
          </FormHelperText>
        </div>
      </div>
    )}
    {isSecureBoot?.name && (
      <input
        name={isSecureBoot.name}
        type="hidden"
        value={isSecureBoot?.value || '0'}
      />
    )}
  </>
);

SecureBoot.propTypes = {
  bios: PropTypes.object,
  isSecureBoot: PropTypes.object,
  efiDiskSelected: PropTypes.bool,
};

SecureBoot.defaultProps = {
  bios: {},
  isSecureBoot: {},
  efiDiskSelected: false,
};

export default SecureBoot;
