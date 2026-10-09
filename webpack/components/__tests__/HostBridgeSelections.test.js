/* eslint-disable jquery/no-trigger */
import $ from 'jquery';
import { watchHostBridgeSelections } from '../hooks/useHostBridgeSelections';

describe('Rails host bridge fields', () => {
  let form;
  let stop;
  beforeEach(() => {
    window.update_interface_table = jest.fn();
    form = document.createElement('form');
    form.innerHTML = `
      <div id="interfaceHidden1" data-interface-id="1">
        <input class="destroyFlag" value="0" />
        <fieldset><div class="form-group"><select name="bridge" data-proxmox-bridge>
          <option value=""></option><option value="saved" selected>saved</option>
        </select></div></fieldset>
      </div>`;
    document.body.appendChild(form);
  });
  afterEach(() => {
    if (stop) stop();
    form.remove();
    delete window.update_interface_table;
  });

  it('preserves a saved selection, clears validation on change, and does not emit user changes during refresh', () => {
    const onChange = jest.fn();
    form.addEventListener('change', onChange);
    stop = watchHostBridgeSelections(form, [{ iface: 'other' }], 'ready');
    const select = form.querySelector('select');
    expect(select.value).toBe('saved');
    expect(new FormData(form).get('bridge')).toBe('saved');
    expect(select.selectedOptions[0].textContent).toBe('saved (unavailable)');
    expect(form.checkValidity()).toBe(false);
    expect(window.update_interface_table).toHaveBeenCalledTimes(1);
    expect(onChange).not.toHaveBeenCalled();
    select.value = 'other';
    select.dispatchEvent(new Event('change', { bubbles: true }));
    expect(form.checkValidity()).toBe(true);
    expect(window.update_interface_table).toHaveBeenCalledTimes(2);
    expect(new FormData(form).get('bridge')).toBe('other');
  });

  it.each(['loading', 'error'])(
    'does not label an unknown bridge unavailable during %s',
    state => {
      stop = watchHostBridgeSelections(form, [], state);
      const select = form.querySelector('select');
      expect(select.selectedOptions[0].textContent).toBe('saved');
      expect(select.checkValidity()).toBe(false);
    }
  );

  it('handles modal clones, blank choices, inactive fieldsets and removed NICs', async () => {
    stop = watchHostBridgeSelections(form, [{ iface: 'other' }], 'ready');
    const clone = form.firstElementChild.cloneNode(true);
    clone.id = 'modal';
    form.appendChild(clone);
    await Promise.resolve();
    const select = clone.querySelector('select');
    expect(select.value).toBe('saved');
    expect(select.checkValidity()).toBe(false);
    select.value = '';
    select.dispatchEvent(new Event('change', { bubbles: true }));
    expect(select.checkValidity()).toBe(true);
    clone.remove();
    const fieldset = form.querySelector('fieldset');
    fieldset.disabled = true;
    await Promise.resolve();
    expect(form.querySelector('select').validationMessage).toBe('');
    fieldset.disabled = false;
    form.querySelector('.destroyFlag').value = '1';
    await Promise.resolve();
    expect(form.checkValidity()).toBe(true);
  });

  it('ignores templates and clears validation when disconnected', () => {
    form.firstElementChild.className = 'form_template';
    stop = watchHostBridgeSelections(form, [], 'ready');
    expect(form.checkValidity()).toBe(true);
    stop();
    expect(form.querySelector('select').validationMessage).toBe('');
  });

  it('exempts a newly saved NIC without a data attribute when its row is removed', async () => {
    form.firstElementChild.removeAttribute('data-interface-id');
    const row = document.createElement('div');
    row.id = 'interface1';
    form.appendChild(row);
    stop = watchHostBridgeSelections(form, [], 'ready');
    const select = form.querySelector('select');
    expect(select.checkValidity()).toBe(false);
    row.remove();
    form.querySelector('.destroyFlag').value = '1';
    await Promise.resolve();
    expect(select.checkValidity()).toBe(true);
    expect(form.querySelector('.has-error')).toBeNull();
  });

  it('preserves independent server errors when resource errors clear or the watcher stops', () => {
    const wrapper = form.querySelector('.form-group');
    stop = watchHostBridgeSelections(form, [], 'ready');
    wrapper.insertAdjacentHTML(
      'beforeend',
      '<span class="error-message">Server error</span>'
    );
    stop();
    expect(wrapper).toHaveClass('has-error');
    expect(wrapper.querySelector('[data-resource-error]')).toBeNull();
    expect(wrapper).toHaveTextContent('Server error');
  });

  it.each(['ready', 'loading', 'error', 'parent'])(
    'clears a dismissed dialog copy without exempting the saved NIC during %s',
    async availability => {
      const original = form.firstElementChild;
      const savedBridge = original.querySelector('select');
      const modal = document.createElement('div');
      modal.id = 'interfaceModal';
      modal.className = 'modal';
      modal.innerHTML = original.innerHTML;
      form.appendChild(modal);
      const row = document.createElement('div');
      row.id = 'interface1';
      form.appendChild(row);
      stop = watchHostBridgeSelections(form, [], availability);
      const clone = modal.querySelector('select');
      expect(clone.checkValidity()).toBe(true);
      expect(savedBridge.checkValidity()).toBe(false);

      modal.classList.add('in');
      $(modal).trigger('shown.bs.modal');
      expect(clone.checkValidity()).toBe(false);
      expect(clone.closest('.form-group')).toHaveClass('has-error');
      modal.classList.remove('in');
      $(modal).trigger('hidden.bs.modal');
      expect(clone.value).toBe('saved');
      expect(clone.checkValidity()).toBe(true);
      expect(clone.closest('.form-group')).not.toHaveClass('has-error');
      expect(savedBridge.checkValidity()).toBe(false);

      modal.classList.add('in');
      $(modal).trigger('shown.bs.modal');
      expect(clone.checkValidity()).toBe(false);
      modal.classList.remove('in');
      $(modal).trigger('hidden.bs.modal');
      row.remove();
      original.querySelector('.destroyFlag').value = '1';
      await Promise.resolve();
      expect(form.checkValidity()).toBe(true);

      stop();
      modal.classList.add('in');
      $(modal).trigger('shown.bs.modal');
      expect(clone.checkValidity()).toBe(true);
    }
  );

  it.each(['loading', 'error', 'parent'])(
    'allows an unbridged NIC during %s',
    state => {
      form.querySelector('select').value = '';
      stop = watchHostBridgeSelections(form, [], state);
      expect(form.checkValidity()).toBe(true);
      expect(form.querySelector('.has-error')).toBeNull();
    }
  );
});
