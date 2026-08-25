import React from 'react';
import { act, cleanup, render, screen, waitFor } from '@testing-library/react';
import { API } from 'foremanReact/redux/API';
import ProxmoxVmType from '../ProxmoxVmType';

jest.mock('foremanReact/redux/API', () => ({ API: { get: jest.fn() } }));

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
    window.update_interface_table = jest.fn();
    window.tfm = { tools: { highlightTabErrors: jest.fn() } };
    jest.useFakeTimers();
    API.get.mockReset();
    mockGeneralTabContent.mockClear();
  });

  afterEach(() => {
    cleanup();
    delete window.update_interface_table;
    delete window.tfm;
    jest.clearAllTimers();
    jest.useRealTimers();
    const imageSelection = document.querySelector('#image_selection');
    if (imageSelection) imageSelection.remove();
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

  it('updates Rails bridge fields and displays their validation error after metadata loads', async () => {
    let complete;
    API.get.mockImplementation(
      () =>
        new Promise(resolve => {
          complete = resolve;
        })
    );
    const { container } = render(
      <form>
        <div className="form-group">
          <select name="bridge" data-proxmox-bridge defaultValue="saved">
            <option value="saved">saved</option>
          </select>
        </div>
        <ProxmoxVmType
          {...baseProps}
          vmAttrs={{
            ...baseProps.vmAttrs,
            nodeId: { name: 'node', value: 'node-a' },
          }}
          computeResourceId={1}
        />
      </form>
    );
    const select = container.querySelector('select');
    expect(select.value).toBe('saved');
    expect(select.validationMessage).toContain('loading');
    await act(async () =>
      complete({
        data: {
          nodes: [{ node: 'node-a' }],
          bridges: [{ node_id: 'node-a', iface: 'other' }],
          storages: [],
          pools: [],
          images: [],
        },
      })
    );
    expect(select.value).toBe('saved');
    expect(select.checkValidity()).toBe(false);
    expect(select.closest('.form-group')).toHaveClass('has-error');
    expect(container.querySelector('.help-block')).toHaveTextContent(
      'Select an available resource'
    );
  });

  it('restores a compute profile image after Foreman reloads image options', async () => {
    document.body.insertAdjacentHTML(
      'afterbegin',
      '<div id="image_selection"><select name="host[compute_attributes][image_id]"></select></div>'
    );
    const imageSelect = document.querySelector('#image_selection select');

    render(
      <ProxmoxVmType
        {...baseProps}
        vmAttrs={{
          ...baseProps.vmAttrs,
          imageId: {
            name: 'host[compute_attributes][image_id]',
            value: 'template-9000',
          },
        }}
      />
    );

    act(() => {
      imageSelect.replaceChildren(
        new Option('Other image', 'template-8000'),
        new Option('Profile image', 'template-9000')
      );
    });

    await waitFor(() => expect(imageSelect).toHaveValue('template-9000'));
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
      expect(props.offlineNodes).toEqual(['offline-node']);
    });
  });

  it('shows the offline warning without placement choices when every node is offline', async () => {
    API.get.mockResolvedValue({
      data: {
        nodes: [],
        offline_nodes: ['node-a', 'node-b'],
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
        'The following Proxmox nodes are offline and unavailable: node-a, node-b'
      )
    ).toBeInTheDocument();
    const [props] = mockGeneralTabContent.mock.calls.slice(-1)[0];
    expect(props.nodesMap).toEqual([]);
  });
});
