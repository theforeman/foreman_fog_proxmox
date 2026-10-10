/* eslint-disable jquery/no-data, jquery/no-trigger */
import $ from 'jquery';
import { watchResourceValidation } from '../hooks/useResourceValidation';

describe('resource error navigation', () => {
  let form;
  let stop;
  let setActiveTab;
  beforeEach(() => {
    jest.useFakeTimers();
    jest
      .spyOn(window, 'requestAnimationFrame')
      .mockImplementation(callback => setTimeout(callback, 0));
    jest
      .spyOn(window, 'cancelAnimationFrame')
      .mockImplementation(id => clearTimeout(id));
    window.tfm = { tools: { highlightTabErrors: jest.fn() } };
    window.edit_interface = jest.fn();
    form = document.createElement('form');
    form.innerHTML = `
      <a href="#compute" data-toggle="tab">VM</a>
      <a href="#interfaces" data-toggle="tab">Interfaces</a>
      <div class="tab-content">
        <div id="compute" class="tab-pane">
          <div data-resource-tab="4">
            <div class="form-group has-error">
              <select data-resource-select name="storage">
                <option value="saved">saved (unavailable)</option>
              </select>
            </div>
          </div>
        </div>
        <div id="interfaces" class="tab-pane">
          <div id="interfaceForms">
            <div id="interfaceHidden1" class="hidden">
              <div class="form-group has-error">
                <select data-proxmox-bridge name="bridge"><option value="saved">saved</option></select>
              </div>
            </div>
          </div>
          <div id="interfaceModal"><div class="modal-body">Unsaved edits</div></div>
        </div>
      </div>`;
    document.body.appendChild(form);
    form
      .querySelectorAll('select')
      .forEach(select => select.setCustomValidity('Choose a resource'));
    setActiveTab = jest.fn();
    stop = watchResourceValidation(form, setActiveTab);
  });
  afterEach(() => {
    stop();
    form.remove();
    delete window.tfm;
    delete window.edit_interface;
    jest.clearAllTimers();
    jest.restoreAllMocks();
    jest.useRealTimers();
  });

  it('delegates tab errors to Foreman once per attempt and opens the nested resource tab', () => {
    expect(window.tfm.tools.highlightTabErrors).not.toHaveBeenCalled();
    expect(form.checkValidity()).toBe(false);
    jest.runAllTimers();
    expect(window.tfm.tools.highlightTabErrors).toHaveBeenCalledTimes(1);
    expect(setActiveTab).toHaveBeenCalledWith(4);
    expect(document.activeElement).toBe(form.querySelector('[name="storage"]'));
    expect(window.edit_interface).not.toHaveBeenCalled();
  });

  it.each(['closed', 'dismissed', 'open'])(
    'leaves a %s NIC dialog untouched and relies on Foreman for tab highlighting',
    state => {
      const modal = form.querySelector('#interfaceModal');
      if (state !== 'closed') $(modal).data('current-id', '1');
      if (state === 'open') modal.classList.add('in');
      const previousContent = modal.outerHTML;
      const bridge = form.querySelector('[name="bridge"]');
      const focus = jest.spyOn(bridge, 'focus');
      bridge.checkValidity();
      jest.runAllTimers();
      expect(window.tfm.tools.highlightTabErrors).toHaveBeenCalledTimes(1);
      expect(setActiveTab).not.toHaveBeenCalled();
      expect(window.edit_interface).not.toHaveBeenCalled();
      expect(modal.outerHTML).toBe(previousContent);
      $(form).trigger('shown.bs.tab');
      jest.runAllTimers();
      expect(focus).not.toHaveBeenCalled();
    }
  );

  it('recomputes stale tab indicators on submission but leaves Foreman indicators on cleanup', () => {
    const tab = form.querySelector('a');
    tab.classList.add('tab-error');
    form.querySelector('select').checkValidity();
    jest.runAllTimers();
    expect(tab).not.toHaveClass('tab-error');
    tab.classList.add('tab-error');
    stop();
    expect(tab).toHaveClass('tab-error');
  });

  it('ignores unrelated invalid events and cancels pending navigation on cleanup', () => {
    const unrelated = document.createElement('input');
    form.appendChild(unrelated);
    const event = new Event('invalid', { cancelable: true });
    unrelated.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(false);
    form.querySelector('select').checkValidity();
    stop();
    jest.runAllTimers();
    expect(window.tfm.tools.highlightTabErrors).not.toHaveBeenCalled();
  });
});
