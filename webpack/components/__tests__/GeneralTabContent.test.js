import React from 'react';
import { render, screen } from '@testing-library/react';
import GeneralTabContent from '../GeneralTabContent';

describe('GeneralTabContent', () => {
  const general = {
    type: { value: 'qemu' },
    nodeId: {
      name: 'host[compute_attributes][node_id]',
      value: 'node-a',
    },
    isoUploadStorage: {
      name: 'host[compute_attributes][iso_upload_storage]',
      value: 'shared-iso',
    },
  };

  const storages = [
    {
      storage: 'shared-iso',
      node_id: 'node-a',
      content: 'iso,backup',
      avail: 1000,
      used: 1000,
      total: 2000,
    },
    {
      storage: 'other-node-iso',
      node_id: 'node-b',
      content: 'iso',
      avail: 1000,
      used: 1000,
      total: 2000,
    },
    {
      storage: 'images-only',
      node_id: 'node-a',
      content: 'images',
      avail: 1000,
      used: 1000,
      total: 2000,
    },
  ];

  it('offers ISO-capable storages for the selected node', () => {
    const { container } = render(
      <GeneralTabContent
        general={general}
        storages={storages}
        newVm
        provisionMethod="image"
        handleChange={jest.fn()}
      />
    );

    const isoUploadStorage = container.querySelector(
      'select[name="host[compute_attributes][iso_upload_storage]"]'
    );
    expect(isoUploadStorage).toHaveValue('shared-iso');
    expect(isoUploadStorage).toBeEnabled();
    expect(
      screen.getByRole('option', { name: /shared-iso/ })
    ).toBeInTheDocument();
    expect(
      screen.queryByRole('option', { name: /other-node-iso/ })
    ).not.toBeInTheDocument();
    expect(
      screen.queryByRole('option', { name: /images-only/ })
    ).not.toBeInTheDocument();
  });

  it('does not select an ISO upload storage by default', () => {
    const { container } = render(
      <GeneralTabContent
        general={{
          ...general,
          isoUploadStorage: { ...general.isoUploadStorage, value: '' },
        }}
        storages={storages}
        newVm
        provisionMethod="image"
        handleChange={jest.fn()}
      />
    );

    expect(
      container.querySelector(
        'select[name="host[compute_attributes][iso_upload_storage]"]'
      )
    ).toHaveValue('');
  });

  it('enables ISO upload storage for bootdisk provisioning', () => {
    const { container } = render(
      <GeneralTabContent
        general={general}
        storages={storages}
        newVm
        provisionMethod="bootdisk"
        handleChange={jest.fn()}
      />
    );

    const isoUploadStorage = container.querySelector(
      'select[name="host[compute_attributes][iso_upload_storage]"]'
    );
    expect(isoUploadStorage).toBeEnabled();
  });

  it('disables ISO upload storage for provisioning without an ISO', () => {
    const { container } = render(
      <GeneralTabContent
        general={general}
        storages={storages}
        newVm
        provisionMethod="build"
        handleChange={jest.fn()}
      />
    );

    const isoUploadStorage = container.querySelector(
      'select[name="host[compute_attributes][iso_upload_storage]"]'
    );
    expect(isoUploadStorage).toBeDisabled();
  });

  it('shows the missing ISO storage message for bootdisk provisioning', () => {
    render(
      <GeneralTabContent
        general={general}
        storages={[]}
        newVm
        provisionMethod="bootdisk"
        handleChange={jest.fn()}
      />
    );

    expect(
      screen.getByText(
        'No ISO storage is available for the selected node. Try selecting another node.'
      )
    ).toBeInTheDocument();
  });

  it('disables ISO upload storage and shows a message when none is available', () => {
    const { container } = render(
      <GeneralTabContent
        general={general}
        storages={storages.filter(storage => storage.node_id !== 'node-a')}
        newVm
        provisionMethod="image"
        handleChange={jest.fn()}
      />
    );

    const isoUploadStorage = container.querySelector(
      'select[name="host[compute_attributes][iso_upload_storage]"]'
    );
    expect(isoUploadStorage).toBeDisabled();
    expect(
      screen.getByText(
        'No ISO storage is available for the selected node. Try selecting another node.'
      )
    ).toBeInTheDocument();
  });

  it('hides ISO upload storage when editing a VM', () => {
    const { container } = render(
      <GeneralTabContent
        general={general}
        storages={storages}
        provisionMethod="image"
        handleChange={jest.fn()}
      />
    );

    expect(
      container.querySelector(
        'select[name="host[compute_attributes][iso_upload_storage]"]'
      )
    ).not.toBeInTheDocument();
  });

  it('shows ISO upload storage in a compute profile', () => {
    const profileGeneral = {
      ...general,
      isoUploadStorage: {
        name: 'compute_attribute[vm_attrs][iso_upload_storage]',
        value: 'shared-iso',
      },
    };
    const { container } = render(
      <GeneralTabContent
        general={profileGeneral}
        storages={storages}
        fromProfile
        handleChange={jest.fn()}
      />
    );

    const isoUploadStorage = container.querySelector(
      'select[name="compute_attribute[vm_attrs][iso_upload_storage]"]'
    );
    expect(isoUploadStorage).toHaveValue('shared-iso');
    expect(isoUploadStorage).toBeEnabled();
  });
});
