import { useEffect } from 'react';
import $ from 'jquery';

export const watchResourceValidation = (form, setActiveTab) => {
  let pending = null;
  let frame = null;
  let control = null;

  const focus = () => {
    cancelAnimationFrame(frame);
    frame = requestAnimationFrame(() => {
      if (!control?.isConnected || control.closest('#interfaceForms')) return;
      const select2 = $(control).data('select2'); // eslint-disable-line jquery/no-data
      const target = select2 ? select2.$selection[0] : control;
      target.focus();
      if (document.activeElement === target) control = null;
    });
  };

  const invalid = event => {
    if (
      !event.target.matches(
        'select[data-resource-select], select[data-proxmox-bridge]'
      )
    )
      return;
    event.preventDefault();
    if (pending !== null) return;
    cancelAnimationFrame(frame);
    control = event.target;
    pending = setTimeout(() => {
      pending = null;
      if (
        !control?.isConnected ||
        control.validity.valid ||
        !control.willValidate
      )
        return;
      // Recompute tab errors on each attempt, including existing server errors.
      form
        .querySelectorAll('.tab-error')
        .forEach(tab => tab.classList.remove('tab-error'));
      window.tfm.tools.highlightTabErrors();
      // Foreman's helper handles Bootstrap tabs, but not controlled PatternFly tabs.
      const tab = control.closest('[data-resource-tab]');
      if (tab) setActiveTab(Number(tab.dataset.resourceTab));
      if (control.closest('#interfaceForms')) {
        control = null;
        return;
      }
      focus();
    }, 0);
  };

  form.addEventListener('invalid', invalid, true);
  $(form).on('shown.bs.tab.resourceValidation', focus);
  return () => {
    form.removeEventListener('invalid', invalid, true);
    clearTimeout(pending);
    cancelAnimationFrame(frame);
    $(form).off('.resourceValidation');
  };
};

const useResourceValidation = (rootRef, setActiveTab) => {
  useEffect(() => {
    const form = rootRef.current?.closest('form');
    if (!form) return undefined;
    return watchResourceValidation(form, setActiveTab);
  }, [rootRef, setActiveTab]);
};

export default useResourceValidation;
