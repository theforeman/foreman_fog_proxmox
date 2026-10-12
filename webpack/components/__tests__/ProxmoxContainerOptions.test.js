import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import ProxmoxContainerOptions from '../ProxmoxContainer/ProxmoxContainerOptions';

jest.mock('../ProxmoxStoragesUtils', () => ({
  createStoragesMap: () => [],
  imagesByStorage: () => [],
}));

jest.mock('../hooks/useVolumes', () => () => ({
  volumes: [],
  loadingVolumes: false,
  volumeError: null,
}));

describe('ProxmoxContainerOptions', () => {
  const options = {
    ostemplateStorage: { name: 'storage', value: 'local' },
    ostemplateFile: { name: 'ostemplate', value: '' },
    password: { name: 'password', value: '' },
    onboot: { name: 'onboot', value: '0' },
    unprivileged: { name: 'unprivileged', value: '1' },
    ostype: { name: 'ostype', value: 'debian' },
    hostname: { name: 'hostname', value: '' },
    nameserver: { name: 'nameserver', value: '' },
    searchdomain: { name: 'searchdomain', value: '' },
  };

  it('enables the unprivileged option for direct container creation', () => {
    const { container } = render(
      <ProxmoxContainerOptions options={options} newVm />
    );

    const checkbox = container.querySelector('input[name="unprivileged"]');
    expect(checkbox).toBeEnabled();
    expect(checkbox).toBeChecked();
  });

  it('disables the unprivileged option when editing a container', () => {
    const { container } = render(
      <ProxmoxContainerOptions options={options} />
    );

    expect(
      container.querySelector('input[name="unprivileged"]')
    ).toBeDisabled();
  });

  it('disables the unprivileged option for image-based deployment', async () => {
    const { container } = render(
      <ProxmoxContainerOptions options={options} newVm imageBased />
    );

    const checkbox = container.querySelector('input[name="unprivileged"]');
    expect(checkbox).toBeDisabled();
    fireEvent.click(container.querySelector('.field-help'));
    expect(
      await screen.findByText(
        'Image-based deployments inherit this setting from the selected template.'
      )
    ).toBeInTheDocument();
  });
});
