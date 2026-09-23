import React from 'react';
import { act, render, screen, waitFor } from '@testing-library/react';
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
    Object.keys(replacements).reduce(
      (text, key) => text.replace(`%(${key})s`, replacements[key]),
      value
    ),
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

  afterEach(() => {
    const imageSelection = document.querySelector('#image_selection');
    if (imageSelection) imageSelection.remove();
    const nicForm = document.querySelector('#nic-form');
    if (nicForm) nicForm.remove();
  });

  beforeEach(() => {
    API.get.mockReset();
    mockGeneralTabContent.mockClear();
  });

  it('refreshes host NIC bridge choices on node changes without replacing the selection', async () => {
    document.body.insertAdjacentHTML(
      'beforeend',
      `<form id="nic-form"><select data-proxmox-bridge name="host[interfaces_attributes][0][compute_attributes][bridge]">
        <option value="vmbr9" selected>vmbr9</option>
      </select></form>`
    );
    API.get.mockResolvedValue({
      data: {
        nodes: [{ node: 'node-a' }, { node: 'node-b' }],
        bridges: [{ node_id: 'node-b', iface: 'vmbr1' }],
      },
    });
    const { unmount } = render(
      <ProxmoxVmType
        {...baseProps}
        computeResourceId={1}
        vmAttrs={{
          ...baseProps.vmAttrs,
          nodeId: {
            name: 'host[compute_attributes][node_id]',
            value: 'node-a',
          },
        }}
      />
    );
    const select = document.querySelector('#nic-form select');
    await waitFor(() =>
      expect(select.selectedOptions[0].textContent).toBe('vmbr9 (unavailable)')
    );

    const [props] = mockGeneralTabContent.mock.calls.slice(-1)[0];
    act(() =>
      props.handleChange({
        target: {
          name: 'host[compute_attributes][node_id]',
          value: 'node-b',
        },
      })
    );

    await waitFor(() =>
      expect(Array.from(select.options, option => option.value)).toEqual([
        '',
        'vmbr9',
        'vmbr1',
      ])
    );
    expect(select.value).toBe('vmbr9');
    unmount();
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
});
