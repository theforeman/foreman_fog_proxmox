import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { API } from 'foremanReact/redux/API';
import ProxmoxVmType from '../ProxmoxVmType';

jest.mock('foremanReact/redux/API', () => ({
  API: {
    get: jest.fn(),
  },
}));

jest.mock('foremanReact/common/I18n', () => ({
  translate: value => value,
  sprintf: (value, replacements) =>
    value.replace('%(nodes)s', replacements.nodes),
}));

/* eslint-disable react/prop-types */
jest.mock('@patternfly/react-core', () => {
  const patternfly = jest.requireActual('@patternfly/react-core');

  return {
    ...patternfly,
    Tabs: ({ children }) => <div>{children}</div>,
    Tab: ({ children, title }) => (
      <div>
        {title}
        {children}
      </div>
    ),
  };
});
/* eslint-enable react/prop-types */

jest.mock('../ProxmoxVmUtils', () => ({
  networkSelected: jest.fn(),
}));

const mockGeneralTabContent = jest.fn(() => (
  <div data-testid="general-tab-content" />
));
jest.mock('../GeneralTabContent', () => props => mockGeneralTabContent(props));

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

  beforeEach(() => {
    API.get.mockReset();
    mockGeneralTabContent.mockClear();
  });

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

  it('filters offline nodes and displays their names', async () => {
    API.get.mockResolvedValue({
      data: {
        nodes: [{ node: 'online-node' }],
        offline_nodes: ['offline-node'],
        pools: [],
        storages: [],
        bridges: [],
        images: [],
      },
    });

    render(
      <ProxmoxVmType {...baseProps} computeResourceId={1} propsLoaded={false} />
    );

    expect(
      await screen.findByText(
        'The following Proxmox nodes are offline and unavailable: offline-node'
      )
    ).toBeInTheDocument();
    await waitFor(() => {
      const { calls } = mockGeneralTabContent.mock;
      const [lastCall] = calls.slice(-1);
      const [props] = lastCall;
      expect(props.nodesMap).toEqual([
        { value: 'online-node', label: 'online-node' },
      ]);
    });
  });
});
