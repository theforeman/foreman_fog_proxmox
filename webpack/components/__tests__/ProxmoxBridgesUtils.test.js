import { waitFor } from '@testing-library/react';
import {
  bridgeOptions,
  observeHostBridgeOptions,
} from '../ProxmoxBridgesUtils';

describe('Proxmox bridge choices', () => {
  let disconnect;

  afterEach(() => {
    if (disconnect) disconnect();
    document.body.innerHTML = '';
  });

  const addForm = () => {
    document.body.innerHTML = `
      <form id="host-form">
        <select data-proxmox-bridge name="nic0[bridge]">
          <option value="vmbr0">vmbr0</option>
          <option value="vmbr9" selected>vmbr9</option>
        </select>
        <select data-proxmox-bridge name="nic1[bridge]">
          <option value="" selected></option>
          <option value="vmbr0">vmbr0</option>
        </select>
        <select name="unrelated"><option value="untouched">untouched</option></select>
      </form>`;
    return document.querySelector('form');
  };

  it('preserves every NIC value in an unchanged form submission', () => {
    const form = addForm();
    const before = Array.from(new FormData(form));
    const changed = jest.fn();
    form.addEventListener('change', changed);

    disconnect = observeHostBridgeOptions([
      { iface: 'vmbr0' },
      { iface: 'vmbr9' },
    ]);

    expect(Array.from(new FormData(form))).toEqual(before);
    expect(changed).not.toHaveBeenCalled();
  });

  it('retains missing bridges and refreshes choices without selecting a replacement', () => {
    const form = addForm();
    disconnect = observeHostBridgeOptions([]);
    const select = form.querySelector('select');
    expect(select.value).toBe('vmbr9');
    expect(select.selectedOptions[0].textContent).toBe('vmbr9 (unavailable)');

    disconnect();
    disconnect = observeHostBridgeOptions([{ iface: 'vmbr1' }]);
    expect(select.value).toBe('vmbr9');
    expect(Array.from(select.options, option => option.value)).toEqual([
      '',
      'vmbr9',
      'vmbr1',
    ]);
    expect(new FormData(form).get('nic0[bridge]')).toBe('vmbr9');

    select.value = 'vmbr1';
    disconnect();
    disconnect = observeHostBridgeOptions([{ iface: 'vmbr1' }]);
    expect(select.value).toBe('vmbr1');
    expect(Array.from(select.options, option => option.value)).toEqual([
      '',
      'vmbr1',
    ]);
  });

  it('refreshes asynchronously added NIC forms and preserves their selected values', async () => {
    const form = addForm();
    disconnect = observeHostBridgeOptions([{ iface: 'vmbr2' }]);
    form.insertAdjacentHTML(
      'beforeend',
      `<div><select data-proxmox-bridge name="nic2[bridge]">
        <option value="vmbr8" selected>vmbr8</option>
      </select></div>`
    );

    const select = form.querySelector('[name="nic2[bridge]"]');
    await waitFor(() => expect(select.options).toHaveLength(3));
    expect(select.value).toBe('vmbr8');
    expect(new FormData(form).get('nic2[bridge]')).toBe('vmbr8');
    // Foreman's NIC modal clones the options, including defaultSelected.
    expect(select.cloneNode(true).value).toBe('vmbr8');
  });

  it('stops updating forms after cleanup', async () => {
    addForm();
    disconnect = observeHostBridgeOptions([{ iface: 'vmbr2' }]);
    disconnect();
    document
      .querySelector('form')
      .insertAdjacentHTML(
        'beforeend',
        '<select data-proxmox-bridge name="added"><option value="saved">saved</option></select>'
      );
    await Promise.resolve();
    expect(document.querySelector('[name="added"]').options).toHaveLength(1);
  });

  it('keeps a saved bridge once, and treats an unattached NIC as an explicit blank selection', () => {
    expect(bridgeOptions([{ iface: 'vmbr9' }], 'vmbr9')).toEqual([
      { value: '', label: '' },
      { value: 'vmbr9', label: 'vmbr9' },
    ]);
    expect(bridgeOptions([{ iface: 'vmbr0' }], '')[0]).toEqual({
      value: '',
      label: '',
    });
  });
});
