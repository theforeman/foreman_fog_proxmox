// Copyright 2018 Tristan Robert

// This file is part of ForemanFogProxmox.

// ForemanFogProxmox is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// ForemanFogProxmox is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

function cdromSelected(item) {
  var selected = $(item).val();
  var index = getIndex(item);
  var cdrom_image_form_id = '#cdrom_image_form_' + index;

  switch (selected) {
    case 'none':
      initCdromStorage(index);
      initCdromOptions(index,'volid');
      disableField(cdrom_image_form_id);
      break;
    case 'cdrom':
      initCdromStorage(index);
      initCdromOptions(index,'volid');
      disableField(cdrom_image_form_id);
      break;
    case 'image':
      initCdromStorage(index);
      initCdromOptions(index,'volid');
      enableField(cdrom_image_form_id);
      break;
    default:
      break;
  }
  return false;
}

function initCdromStorage(index) {
  var select = '#host_compute_attributes_volumes_attributes_' + index + '_storage';
  $(select + ' option:selected').prop('selected', false);
  $(select).val('');
}

function initCdromOptions(index, name) {
  var select = '#host_compute_attributes_volumes_attributes_' + index + '_' + name;
  $(select).empty();
  $(select).append($("<option></option>").val('').text(''));
  $(select).val('');
}

function storageIsoSelected(item) {
  var index = getIndex(item);
  var storage = $(item).val();
  var node_id = $('#host_compute_attributes_node_id').val();
  updateOptions('isos', 'compute_attributes_volumes_attributes_' + index , 'volid', undefined, undefined, 'volid', node_id, storage);
}