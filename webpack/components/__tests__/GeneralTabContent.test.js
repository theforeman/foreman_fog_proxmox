import React from 'react';
import { render, screen } from '@testing-library/react';
import GeneralTabContent from '../GeneralTabContent';

const baseGeneral = {
  vmid: { name: 'host[compute_attributes][vmid]', value: '100' },
  nodeId: { name: 'host[compute_attributes][node_id]', value: 'node1' },
  pool: { name: 'host[compute_attributes][pool]', value: '' },
  startAfterCreate: {
    name: 'host[compute_attributes][start_after_create]',
    value: '0',
  },
  templated: { name: 'host[compute_attributes][templated]', value: '0' },
  imageId: { name: 'compute_attribute[vm_attrs][image_id]', value: '' },
  fullClone: { name: 'compute_attribute[vm_attrs][full_clone]', value: '0' },
  description: { name: 'host[compute_attributes][description]', value: '' },
};

describe('GeneralTabContent', () => {
  it('shows the Full clone checkbox when configuring a compute profile', () => {
    const { container } = render(
      <GeneralTabContent
        general={baseGeneral}
        fromProfile
        handleChange={jest.fn()}
      />
    );

    expect(screen.getByText('Full clone')).toBeInTheDocument();
    const checkbox = container.querySelector(
      'input[name="compute_attribute[vm_attrs][full_clone]"]'
    );
    expect(checkbox).not.toBeNull();
    expect(checkbox).not.toBeChecked();
  });

  it('checks the Full clone checkbox when full_clone is set', () => {
    const { container } = render(
      <GeneralTabContent
        general={{
          ...baseGeneral,
          fullClone: { ...baseGeneral.fullClone, value: '1' },
        }}
        fromProfile
        handleChange={jest.fn()}
      />
    );

    const checkbox = container.querySelector(
      'input[name="compute_attribute[vm_attrs][full_clone]"]'
    );
    expect(checkbox).toBeChecked();
  });

  it('shows the Full clone checkbox enabled when creating a new host with image provisioning', () => {
    const { container } = render(
      <GeneralTabContent
        general={baseGeneral}
        fromProfile={false}
        newVm
        provisionMethodState="image"
        handleChange={jest.fn()}
      />
    );

    expect(screen.getByText('Full clone')).toBeInTheDocument();
    const checkbox = container.querySelector(
      'input[name="compute_attribute[vm_attrs][full_clone]"]'
    );
    expect(checkbox).not.toBeNull();
    expect(checkbox).not.toBeDisabled();
  });

  it('shows the Full clone checkbox disabled when creating a new host with network provisioning', () => {
    const { container } = render(
      <GeneralTabContent
        general={baseGeneral}
        fromProfile={false}
        newVm
        provisionMethodState="build"
        handleChange={jest.fn()}
      />
    );

    expect(screen.getByText('Full clone')).toBeInTheDocument();
    const checkbox = container.querySelector(
      'input[name="compute_attribute[vm_attrs][full_clone]"]'
    );
    expect(checkbox).not.toBeNull();
    expect(checkbox).toBeDisabled();
  });

  it('shows the Full clone checkbox as disabled when editing an existing host', () => {
    const { container } = render(
      <GeneralTabContent
        general={baseGeneral}
        fromProfile={false}
        newVm={false}
        handleChange={jest.fn()}
      />
    );

    expect(screen.getByText('Full clone')).toBeInTheDocument();
    const checkbox = container.querySelector(
      'input[name="compute_attribute[vm_attrs][full_clone]"]'
    );
    expect(checkbox).not.toBeNull();
    expect(checkbox).toBeDisabled();
  });
});
