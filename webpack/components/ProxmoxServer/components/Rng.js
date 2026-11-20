import React, { useState } from 'react';
import { Button, Title, Divider, PageSection } from '@patternfly/react-core';
import { TimesIcon } from '@patternfly/react-icons';
import { translate as __ } from 'foremanReact/common/I18n';
import PropTypes from 'prop-types';
import InputField from '../../common/FormInputs';

const rngSources = ['/dev/urandom', '/dev/random', '/dev/hwrng'];

const Rng = ({ initialRng, paramScope }) => {
  const [rng, setRng] = useState(initialRng);

  const addRng = () => {
    setRng({
      source: {
        name: `${paramScope}[rng_attributes][source]`,
        value: '/dev/urandom',
      },
      max_bytes: {
        name: `${paramScope}[rng_attributes][max_bytes]`,
        value: '',
      },
      period: {
        name: `${paramScope}[rng_attributes][period]`,
        value: '',
      },
    });
  };

  const handleRngChange = e => {
    const { name, value } = e.target;
    const updatedKey = Object.keys(rng).find(key => rng[key].name === name);
    setRng(prevRng => ({
      ...prevRng,
      [updatedKey]: { ...prevRng[updatedKey], value },
    }));
  };

  return (
    <PageSection padding={{ default: 'noPadding' }}>
      <Button
        ouiaId="proxmox-server-hardware-add-rng"
        type="button"
        variant="secondary"
        onClick={addRng}
        isDisabled={Boolean(rng)}
      >
        {__('Add ViritIO RNG')}
      </Button>
      {rng && (
        <div style={{ marginTop: '2rem' }}>
          <div
            style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
            }}
          >
            <Title ouiaId="proxmox-server-hardware-rng" headingLevel="h4">
              {__('ViritIO RNG')}
            </Title>
            <button
              type="button"
              aria-label={__('Remove RNG')}
              title={__('Remove RNG')}
              onClick={() => setRng(null)}
            >
              <TimesIcon />
            </button>
          </div>
          <Divider component="li" style={{ marginBottom: '2rem' }} />
          <InputField
            name={rng.source.name}
            label={__('Entropy source')}
            info={__(
              'Entropy source on the Proxmox host. /dev/urandom is recommended. /dev/hwrng requires a hardware RNG.'
            )}
            type="select"
            value={rng.source.value ?? ''}
            options={rngSources.map(source => ({
              label: source,
              value: source,
            }))}
            onChange={handleRngChange}
          />
          <InputField
            name={rng.max_bytes.name}
            label={__('Limit (Bytes/Period)')}
            info={__(
              'Maximum number of bytes provided per period. Defaults to 1024. Set to 0 to disable rate limiting.'
            )}
            type="number"
            value={rng.max_bytes.value ?? ''}
            placeholder="1024"
            onChange={handleRngChange}
          />
          <InputField
            name={rng.period.name}
            label={__('Period (ms)')}
            info={__(
              'Time interval in milliseconds for the rate limit. Defaults to 1000 ms.'
            )}
            type="number"
            value={rng.period.value ?? ''}
            placeholder="1000"
            onChange={handleRngChange}
          />
        </div>
      )}
    </PageSection>
  );
};

Rng.propTypes = {
  initialRng: PropTypes.object,
  paramScope: PropTypes.string,
};

Rng.defaultProps = {
  initialRng: null,
  paramScope: '',
};

export default Rng;
