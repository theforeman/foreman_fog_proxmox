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
  checked,
}) => {
  const renderOptions = options =>
    options.map(option => <option value={option.value}>{option.label}</option>);

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
          name={name}
          className="form-control"
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
          className=''
          value={value}
	  checked={checked}
          onChange={onChange}
          disabled={disabled}
        />
	);
	break;
	default:
	renderComponent = (
         <input
          name={name}
          type={type}
          className='form-control'
          value={value}
          onChange={onChange}
          disabled={disabled}
        />
	);
	break;
      }

  return (
    <CommonForm label={label} required={required} className="common-textInput">
	  {renderComponent}
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
  checked: PropTypes.bool,
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
