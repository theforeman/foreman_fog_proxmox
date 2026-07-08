import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import { ProxmoxBiosProvider } from '../ProxmoxBiosContext';
import EFIDisk from '../ProxmoxServer/components/EFIDisk';

const efiDiskData = {
  id: { name: 'efidisk[id]', value: 0 },
  volid: { name: 'efidisk[volid]', value: 'local:0' },
  storage: { name: 'efidisk[storage]', value: 'local' },
  format: { name: 'efidisk[format]', value: 'raw' },
  preEnrolledKeys: { name: 'efidisk[pre_enrolled_keys]', value: '0' },
};

const renderEfiDisk = bios =>
  render(
    <ProxmoxBiosProvider initialBios={bios}>
      <EFIDisk
        onRemove={jest.fn()}
        data={efiDiskData}
        storages={[]}
        nodeId="node-1"
        vmId="100"
      />
    </ProxmoxBiosProvider>
  );

describe('EFIDisk', () => {
  it('checks and disables pre-enrolled keys for UEFI Secure Boot', async () => {
    const { container } = renderEfiDisk('uefi_secure_boot');

    const checkbox = screen.getByRole('checkbox');
    const submittedValue = container.querySelector(
      'input[name="efidisk[pre_enrolled_keys]"]'
    );

    expect(checkbox).toBeDisabled();
    expect(checkbox).toBeChecked();
    expect(submittedValue).toHaveValue('1');
    fireEvent.click(container.querySelector('.field-help'));
    expect(
      await screen.findByText(
        'This checkbox is read-only and automatically checked when UEFI Secure Boot is selected'
      )
    ).toBeInTheDocument();
  });

  it('unchecks and disables pre-enrolled keys without UEFI Secure Boot', () => {
    const { container } = renderEfiDisk('ovmf');

    const checkbox = screen.getByRole('checkbox');
    const submittedValue = container.querySelector(
      'input[name="efidisk[pre_enrolled_keys]"]'
    );

    expect(checkbox).toBeDisabled();
    expect(checkbox).not.toBeChecked();
    expect(submittedValue).toHaveValue('0');
  });
});
