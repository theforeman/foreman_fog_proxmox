import $ from 'jquery';

function networkSelected(value) {
  const fieldSets = [];
  fieldSets.push({
    id: 'network',
    toggle: true,
    newVm: true,
    selected: value,
  });
  fieldSets.forEach(toggleFieldsets);
  return false;
}

function enableFieldSet(fieldSetId, fieldSet) {
  if (fieldSet.toggle && fieldSet.newVm) {
    getFieldSetById(fieldSetId, fieldSet).show();
  }
  getFieldSetById(fieldSetId, fieldSet).removeAttr('disabled');
  getInputHiddenById(fieldSetId).removeAttr('disabled');
}

function disableFieldSet(fieldSetId, fieldSet) {
  if (fieldSet.toggle && fieldSet.newVm) {
    getFieldSetById(fieldSetId, fieldSet).hide();
  }
  getFieldSetById(fieldSetId, fieldSet).attr('disabled', 'disabled');
  getInputHiddenById(fieldSetId).attr('disabled', 'disabled');
}

function toggleFieldSet(fieldSetId, fieldSet, type1, type2) {
  type1 === type2
    ? enableFieldSet(fieldSetId, fieldSet)
    : disableFieldSet(fieldSetId, fieldSet);
}

function getInputHiddenById(volumeId) {
  return $(`div[id^='${volumeId}_volumes'] + input:hidden`);
}

function getFieldSetById(fieldSetId, fieldSet) {
  return $(`fieldset[id^='${fieldSetId}_${fieldSet.id}']`);
}

function getFieldSets(type) {
  return type === 'qemu' ? ['server'] : ['container'];
}

function toggleFieldsets(fieldSet) {
  const removableInputHidden = $(
    `div.removable-item[style='display: none;'] + input:hidden`
  );
  removableInputHidden.attr('disabled', 'disabled');
  ['qemu', 'lxc'].forEach(type => {
    getFieldSets(type).forEach(fieldSetId => {
      toggleFieldSet(fieldSetId, fieldSet, fieldSet.selected, type);
    });
  });
}

window.networkSelected = networkSelected;
export { networkSelected };
