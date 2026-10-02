import React from 'react';
import { Tooltip } from '@patternfly/react-core';
import PropTypes from 'prop-types';
import FormField from 'foremanReact/components/common/forms/FormField';

const InputField = ({
  name,
  label,
  info,
  value,
  onChange,
  required,
  type,
  disabled,
  readOnly,
  options,
  checked,
  error,
  tooltip,
}) => {
  const renderOptions = opts =>
    opts.map(option => (
      <option key={option.value} value={option.value}>
        {option.label}
      </option>
    ));

  let renderComponent;

  switch (type) {
    case 'textarea':
      renderComponent = (
        <textarea
          name={name}
          className="form-control"
          rows="3"
          cols="50"
          value={value}
          onChange={onChange}
        />
      );
      break;
    case 'select':
      renderComponent = (
        <select
          disabled={disabled}
          readOnly={readOnly}
          name={name}
          className="without_select2 form-control"
          value={value}
          onChange={onChange}
        >
          {renderOptions(options)}
        </select>
      );
      break;
    case 'checkbox':
      renderComponent = (
        <input
          name={name}
          type={type}
          className=""
          value={value}
          checked={checked}
          onChange={onChange}
          disabled={disabled}
          readOnly={readOnly}
        />
      );
      break;
    default:
      renderComponent = (
        <input
          name={name}
          type={type}
          className="form-control"
          value={value}
          onChange={onChange}
          disabled={disabled}
          readOnly={readOnly}
        />
      );
      break;
  }

  return (
    <FormField
      id={name}
      label={label}
      required={required}
      className="common-textInput"
      labelHelp={info}
      error={error}
    >
      {tooltip ? (
        <Tooltip content={tooltip}>{renderComponent}</Tooltip>
      ) : (
        renderComponent
      )}
    </FormField>
  );
};

InputField.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  info: PropTypes.string,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number,
    PropTypes.bool,
  ]),
  onChange: PropTypes.func.isRequired,
  required: PropTypes.bool,
  type: PropTypes.oneOf([
    'text',
    'number',
    'password',
    'textarea',
    'select',
    'checkbox',
  ]),
  disabled: PropTypes.bool,
  readOnly: PropTypes.bool,
  checked: PropTypes.bool,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string.isRequired,
      value: PropTypes.oneOfType([PropTypes.string, PropTypes.number])
        .isRequired,
    })
  ),
  error: PropTypes.string,
  tooltip: PropTypes.string,
};

InputField.defaultProps = {
  name: '',
  label: '',
  info: undefined,
  value: '',
  required: false,
  type: 'text',
  disabled: false,
  readOnly: false,
  checked: false,
  options: [],
  error: '',
  tooltip: '',
};

export default InputField;
