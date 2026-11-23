import React from 'react';
import PropTypes from 'prop-types';
import {
  FormHelperText,
  HelperText,
  HelperTextItem,
} from '@patternfly/react-core';

const WarningMessage = ({ id, children, style }) => (
  <FormHelperText>
    <HelperText id={id}>
      <HelperTextItem
        variant="warning"
        style={{ fontSize: '0.875rem', lineHeight: 1.5, ...style }}
      >
        {children}
      </HelperTextItem>
    </HelperText>
  </FormHelperText>
);

WarningMessage.propTypes = {
  id: PropTypes.string.isRequired,
  children: PropTypes.node.isRequired,
  style: PropTypes.object,
};

WarningMessage.defaultProps = {
  style: {},
};

export default WarningMessage;
