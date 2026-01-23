import React from 'react';
import { render, screen } from '@testing-library/react';
import ProxmoxVmType from '../ProxmoxVmType';

jest.mock('../ProxmoxVmUtils', () => ({
  networkSelected: jest.fn(),
}));

jest.mock('../GeneralTabContent', () => () => (
  <div data-testid="general-tab-content" />
));

jest.mock('../common/FormInputs', () => () => <div data-testid="type-field" />);

jest.mock('../ProxmoxServer/ProxmoxServerOptions', () => () => <div />);
jest.mock('../ProxmoxServer/ProxmoxServerHardware', () => () => <div />);
jest.mock('../ProxmoxServer/ProxmoxServerNetwork', () => () => <div />);
jest.mock('../ProxmoxServer/ProxmoxServerStorage', () => () => <div />);
jest.mock('../ProxmoxContainer/ProxmoxContainerOptions', () => () => <div />);
jest.mock('../ProxmoxContainer/ProxmoxContainerHardware', () => () => <div />);
jest.mock('../ProxmoxContainer/ProxmoxContainerNetwork', () => () => <div />);
jest.mock('../ProxmoxContainer/ProxmoxContainerStorage', () => () => <div />);

describe('ProxmoxVmType', () => {
  const baseProps = {
    vmAttrs: {
      type: { name: 'type', value: 'qemu' },
    },
    newVm: true,
    bridges: [],
  };

  it('renders Type select and General tab', () => {
    render(<ProxmoxVmType {...baseProps} />);

    expect(screen.getByTestId('type-field')).toBeInTheDocument();
    expect(screen.getByTestId('general-tab-content')).toBeInTheDocument();
  });

  it('renders tabs', () => {
    render(<ProxmoxVmType {...baseProps} />);

    expect(screen.getByText('General')).toBeInTheDocument();
    expect(screen.getByText('Advanced Options')).toBeInTheDocument();
    expect(screen.getByText('Hardware')).toBeInTheDocument();
    expect(screen.getByText('Storage')).toBeInTheDocument();
  });

  it('returns null when registerComp is true', () => {
    const { container } = render(<ProxmoxVmType {...baseProps} registerComp />);

    expect(container.firstChild).toBeNull();
  });
});
