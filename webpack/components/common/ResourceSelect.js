import React, { createContext, useContext } from 'react';
import PropTypes from 'prop-types';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';
import InputField from './FormInputs';

export const ResourceAvailabilityContext = createContext('ready');

export const resourceAvailability = (loading, error) => {
  if (error) return 'error';
  return loading ? 'loading' : 'ready';
};

export const resourceSelection = (
  options,
  value,
  availability = 'ready',
  required = false
) => {
  const selected = value === null || value === undefined ? '' : String(value);
  const present = options.some(option => String(option.value) === selected);
  const unavailable = selected !== '' && !present && availability === 'ready';
  const label = unavailable
    ? sprintf(__('%(value)s (unavailable)'), { value: selected })
    : selected;
  let validationMessage = '';
  if (selected && availability === 'loading') {
    validationMessage = __(
      'Resource availability is still loading. Please wait.'
    );
  } else if ((selected || required) && availability === 'error') {
    validationMessage = __(
      'Resource availability could not be checked. Reload the form to retry.'
    );
  } else if (selected && availability === 'parent') {
    validationMessage = __('Select a node to check resource availability.');
  } else if (unavailable) {
    validationMessage = __(
      'Select an available resource or change the node or storage.'
    );
  }
  return {
    options: present ? options : [{ value: selected, label }, ...options],
    value: selected,
    validationMessage,
  };
};

const ResourceSelect = ({
  options,
  value,
  availability,
  active,
  disabled,
  error,
  defaultToFirst,
  required,
  ...props
}) => {
  const metadataAvailability = useContext(ResourceAvailabilityContext);
  const state =
    metadataAvailability === 'ready'
      ? availability || metadataAvailability
      : metadataAvailability;
  const selected =
    defaultToFirst && !value && state === 'ready'
      ? options[0]?.value || ''
      : value;
  const choices =
    !required && !options.some(option => option.value === '')
      ? [{ value: '', label: '' }, ...options]
      : options;
  const selection = resourceSelection(choices, selected, state, required);
  const validationMessage =
    active && !disabled
      ? selection.validationMessage ||
        (required && !selection.value ? __('Select a resource.') : '')
      : '';
  return (
    <InputField
      {...props}
      {...selection}
      type="select"
      resourceSelect
      disabled={disabled}
      required={required}
      error={state === 'ready' ? error || validationMessage : validationMessage}
      validationMessage={validationMessage}
    />
  );
};

ResourceSelect.propTypes = {
  options: PropTypes.array.isRequired,
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  availability: PropTypes.oneOf(['loading', 'ready', 'error', 'parent']),
  active: PropTypes.bool,
  disabled: PropTypes.bool,
  error: PropTypes.string,
  defaultToFirst: PropTypes.bool,
  required: PropTypes.bool,
};

ResourceSelect.defaultProps = {
  value: '',
  availability: undefined,
  active: true,
  disabled: false,
  error: '',
  defaultToFirst: false,
  required: false,
};

export default ResourceSelect;
