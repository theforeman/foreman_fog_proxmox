import React from 'react';
import {
  FormGroup,
  TextInput,
  ControlLabel,
  Text,
  Flex,
  FlexItem,
  FormSelect,
  FormSelectOption,
} from '@patternfly/react-core';
import Select from 'foremanReact/components/common/forms/Select';
import PropTypes from 'prop-types';
import CommonForm from 'foremanReact/components/common/forms/CommonForm';

const InputField = ({
  name,
  label,
  value,
  onChange,
  required,
  type,
  disabled,
  options,
}) => {
  const renderOptions = opts =>
    options.map(option => <option value={option.value}>{option.label}</option>);

  return (
    <CommonForm label={label} required={required} className="common-textInput">
      {type === 'textarea' ? (
        <textarea
	  name={name}
          className="form-control"
          rows="3"
          cols="50"
          value={value}
          onChange={onChange}
        />
      ) : type === 'select' ? (
        <select
          disabled={disabled}
	  name={name}
          className="form-control"
          value={value}
          onChange={onChange}
        >
          {renderOptions(options)}
        </select>
      ) : (
        <input
	  name={name}
          type={type}
          className={type === 'checkbox' ? '' : 'form-control'}
          value={value}
          onChange={onChange}
          disabled={disabled}
        />
      )}
    </CommonForm>
  );
};

InputField.propTypes = {
  name: PropTypes.string,
  label: PropTypes.string,
  value: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.number,
    PropTypes.bool,
  ]),
  onChange: PropTypes.func.isRequired,
  required: PropTypes.bool,
  type: PropTypes.oneOf(['text', 'number', 'textarea', 'select', 'checkbox']),
  disabled: PropTypes.bool,
  options: PropTypes.arrayOf(
    PropTypes.shape({
      label: PropTypes.string.isRequired,
      value: PropTypes.oneOfType([PropTypes.string, PropTypes.number])
        .isRequired,
    })
  ),
};

InputField.defaultProps = {
  label: '',
  value: '',
  required: false,
  type: 'text',
  disabled: false,
  options: [],
  name: '',
};

export default InputField;
