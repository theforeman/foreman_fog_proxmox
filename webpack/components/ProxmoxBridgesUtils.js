import $ from 'jquery';
import { sprintf, translate as __ } from 'foremanReact/common/I18n';

export const bridgeOptions = (bridges, selectedBridge = '') => {
  const options = bridges.map(bridge => ({
    value: bridge.iface,
    label: bridge.iface,
  }));
  if (
    selectedBridge &&
    !options.some(option => option.value === selectedBridge)
  ) {
    options.unshift({
      value: selectedBridge,
      label: sprintf(__('%(bridge)s (unavailable)'), {
        bridge: selectedBridge,
      }),
    });
  }
  return [{ value: '', label: '' }, ...options];
};

export const observeHostBridgeOptions = bridges => {
  const selector = 'select[data-proxmox-bridge]';
  const refresh = () => {
    document.querySelectorAll(selector).forEach(select => {
      const { value } = select;
      const options = bridgeOptions(bridges, value).map(
        option =>
          new Option(
            option.label,
            option.value,
            option.value === value,
            option.value === value
          )
      );
      select.replaceChildren(...options);
      // Refresh Select2 without firing a user change event on the host form.
      // eslint-disable-next-line jquery/no-trigger
      $(select).trigger('change.select2');
    });
  };

  refresh();
  // Foreman adds and clones NIC forms independently of the React VM form.
  const observer = new MutationObserver(mutations => {
    const addedSelect = mutations.some(mutation =>
      Array.from(mutation.addedNodes).some(
        node =>
          node.nodeType === Node.ELEMENT_NODE &&
          (node.matches(selector) || node.querySelector(selector))
      )
    );
    if (addedSelect) refresh();
  });
  observer.observe(document.body, { childList: true, subtree: true });
  return () => observer.disconnect();
};
