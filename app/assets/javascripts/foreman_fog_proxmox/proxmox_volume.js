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

function getIndex(item) {
  var index_id = $(item).attr('id');
  var pattern = /(host_compute_attributes_volumes_attributes_||compute_attribute_vm_attrs_volumes_attributes_)(\d+)[_](.*)/i;
  pattern_a = pattern.exec(index_id);
  var index = pattern_a[2];
  return index;
}

function volumeId(type,index){
  let volume_id = '#volume_' + type + '_' + index;
  return volume_id;
}

function enableField(item) {
  $(item).show();
  $(item).removeAttr('disabled');
}

function disableField(item) {  
  $(item).hide();
  $(item).attr('disabled','disabled');
}