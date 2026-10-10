import { useEffect } from 'react';
import $ from 'jquery';
import { resourceSelection } from '../common/ResourceSelect';

export const interfaceContainer = select =>
  select.closest('[id^="interfaceHidden"], [data-interface-id]');

export const setBridgeError = (select, message) => {
  select.setCustomValidity(message);
  select.setAttribute('aria-invalid', message ? 'true' : 'false');
  const wrapper = select.closest('.form-group');
  if (!wrapper) return;
  let help = wrapper.querySelector('[data-resource-error]');
  if (message) {
    if (!wrapper.classList.contains('has-error')) {
      wrapper.setAttribute('data-resource-error-owner', '');
      wrapper.classList.add('has-error');
    }
    if (!help) {
      help = document.createElement('span');
      help.className = 'help-block help-inline';
      help.setAttribute('data-resource-error', '');
      select.parentElement.appendChild(help);
    }
    if (help.textContent !== message) help.textContent = message;
  } else {
    if (help) help.remove();
    if (wrapper.hasAttribute('data-resource-error-owner')) {
      if (!wrapper.querySelector('.error-message'))
        wrapper.classList.remove('has-error');
      wrapper.removeAttribute('data-resource-error-owner');
    }
  }
};

export const watchHostBridgeSelections = (form, bridges, availability) => {
  const selector = 'select[data-proxmox-bridge]';
  const options = [
    { value: '', label: '' },
    ...bridges.map(bridge => ({
      value: bridge.iface,
      label: bridge.iface,
    })),
  ];
  const observer = new MutationObserver(() => refresh());
  const refresh = () => {
    observer.disconnect();
    let validationChanged = false;
    form.querySelectorAll(selector).forEach(select => {
      const nic = interfaceContainer(select);
      const removed = nic?.querySelector('.destroyFlag')?.value === '1';
      const template = select.closest('.form_template');
      const modal = select.closest('#interfaceModal');
      const inactive =
        select.disabled ||
        select.closest('fieldset[disabled]') ||
        (modal && !modal.classList.contains('in')) ||
        removed ||
        template;
      const selection = resourceSelection(options, select.value, availability);
      const current = Array.from(select.options, option => ({
        value: option.value,
        label: option.textContent,
      }));
      if (JSON.stringify(current) !== JSON.stringify(selection.options)) {
        select.replaceChildren(
          ...selection.options.map(
            option =>
              new Option(
                option.label,
                option.value,
                option.value === selection.value,
                option.value === selection.value
              )
          )
        );
        // Refresh Select2 without turning a metadata refresh into a user edit.
        $(select).trigger('change.select2'); // eslint-disable-line jquery/no-trigger
      }
      const message = inactive ? '' : selection.validationMessage;
      validationChanged =
        validationChanged ||
        select.getAttribute('aria-invalid') !== (message ? 'true' : 'false');
      setBridgeError(select, message);
    });
    if (validationChanged) window.update_interface_table();
    observer.observe(form, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['disabled'],
    });
  };
  refresh();
  form.addEventListener('change', refresh);
  $(form).on(
    'shown.bs.modal.resourceBridges hidden.bs.modal.resourceBridges',
    '#interfaceModal',
    refresh
  );
  return () => {
    observer.disconnect();
    form.removeEventListener('change', refresh);
    $(form).off('.resourceBridges');
    form.querySelectorAll(selector).forEach(select => {
      setBridgeError(select, '');
      select.removeAttribute('aria-invalid');
    });
    window.update_interface_table();
  };
};

const useHostBridgeSelections = (rootRef, bridges, availability, enabled) => {
  useEffect(() => {
    const form = rootRef.current?.closest('form');
    if (!enabled || !form) return undefined;
    return watchHostBridgeSelections(form, bridges, availability);
  }, [rootRef, bridges, availability, enabled]);
};

export default useHostBridgeSelections;
