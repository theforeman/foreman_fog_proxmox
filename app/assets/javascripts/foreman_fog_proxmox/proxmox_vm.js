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

$(document).on('ContentLoad', tfm.numFields.initAll);
$(document).ready(vmTypeSelected);

function vmTypeSelected() {
  var selected = $("#host_compute_attributes_type").val();
  if (selected == undefined) selected = $("#compute_attribute_vm_attrs_type").val();
  var host_uuid = $("input[id='host_uuid']").val();
  var new_vm =  host_uuid == undefined;
  var fieldsets = [];
  fieldsets.push({id: 'config_advanced_options', toggle: true, new_vm: new_vm, selected: selected});
  fieldsets.push({id: 'config_ext', toggle: true, new_vm: new_vm, selected: selected});
  fieldsets.push({id: 'volume', toggle: true, new_vm: new_vm, selected: selected});
  fieldsets.push({id: 'network', toggle: true, new_vm: true, selected: selected});
  fieldsets.push({id: 'config_options', toggle: false, new_vm: new_vm, selected: selected});
  fieldsets.push({id: 'config_cpu', toggle: false, new_vm: new_vm, selected: selected});
  fieldsets.push({id: 'config_memory', toggle: false, new_vm: new_vm, selected: selected});
  fieldsets.push({id: 'config_cdrom', toggle: false, new_vm: new_vm, selected: selected});
  fieldsets.push({id: 'config_os', toggle: false, new_vm: new_vm, selected: selected});
  fieldsets.push({id: 'config_dns', toggle: false, new_vm: new_vm, selected: selected});
  fieldsets.forEach(toggleFieldsets);
  toggleVolumes(selected);
  return false;
}

function volumeButtonAddId(id){
  return $("a[data-association='" + id + "_volumes']");
}

function volumeFieldsetId(id, type){
  return $("fieldset[id^='" + type + "_volume_"+ id +"']").not("fieldset[id$='_new_" + id +"_volumes']");
}

function indexByIdAndType(id, storage_type, vm_type){
  let regex = new RegExp(`${vm_type}_volume_${storage_type}_(\\d+)`);
  return id.match(regex)[1];
}

function volidByIndexAndTag(index, tag){
  return $(tag + "[id='host_compute_attributes_volumes_attributes_" + index + "_volid']").val();
}

function hasCloudinit(){
  result = false;
  let id = volumeFieldsetId('cloud_init', 'server').attr('id');
  if (id !== undefined){
    let index = indexByIdAndType(id, 'cloud_init', 'server');
    let volid = volidByIndexAndTag(index, 'input');
    result = volid.includes("cloudinit");
  }
  return result;
}

function hasCdrom(){
  result = false;
  let id = volumeFieldsetId('cdrom', 'server').attr('id');
  if (id !== undefined){
    let index = indexByIdAndType(id, 'cdrom', 'server');
    let checked = $("input[id^='host_compute_attributes_volumes_attributes_" + index + "_cdrom']:checked").val();
    let isCdrom = checked === 'cdrom';
    result = isCdrom;
    let isImage = checked === 'image';
    if (isImage) {
      let volid = volidByIndexAndTag(index, 'select');
      result = volid.includes("iso");
    }
  }
  return result;
}

function cloudinit(id){
  return id === 'cloud_init' && hasCloudinit();
}

function cdrom(id){
  return id === 'cdrom' && hasCdrom();
}

function enableVolume(id, type){
  volumeFieldsetId(id, type).show();
  volumeButtonAddId(id).show();
  if (cloudinit(id) || cdrom(id)){
    volumeButtonAddId(id).hide();
  }
  volumeFieldsetId(id, type).removeAttr('disabled');
}

function disableVolume(id, type){
  volumeFieldsetId(id, type).hide();
  volumeButtonAddId(id).hide();
  volumeFieldsetId(id, type).attr('disabled','disabled');
}

function volumes(type){
  return type === 'qemu' ? ['hard_disk', 'cdrom', 'cloud_init'] : ['mp', 'rootfs'];
}

function volume(type){
  return type === 'qemu' ? 'server' : 'container';
}

function toggleVolume(id, type1, type2){
  type1 === type2 ? enableVolume(id, volume(type1)) : disableVolume(id, volume(type1));
}

function toggleVolumes(selected){
   ['qemu', 'lxc'].forEach(function(type){
    volumes(type).forEach(function(id){
      toggleVolume(id, selected, type);
    });
  });
}

function enableFieldset(id, fieldset) {
  if (fieldset.toggle && fieldset.new_vm){
    fieldset_id(id, fieldset).show();
  }
  fieldset_id(id, fieldset).removeAttr('disabled');
  input_hidden_id(id).removeAttr('disabled');
}

function disableFieldset(id, fieldset) {  
  if (fieldset.toggle && fieldset.new_vm){
    fieldset_id(id, fieldset).hide();
  }
  fieldset_id(id, fieldset).attr('disabled','disabled');
  input_hidden_id(id).attr('disabled','disabled');
}

function toggleFieldset(id, fieldset, type1, type2) {  
  type1 === type2 ? enableFieldset(id, fieldset) : disableFieldset(id, fieldset);
}

function input_hidden_id(id){
  return $("div[id^='"+ id +"_volumes']" + " + input:hidden");
}

function fieldset_id(id, fieldset){
  return $("fieldset[id^='" + id + "_"+fieldset.id+"']");
}

function fieldsets(type){
  return type === 'qemu' ? ['server'] : ['container'];
}

function toggleFieldsets(fieldset){
  var removable_input_hidden = $("div.removable-item[style='display: none;']" + " + input:hidden");
  removable_input_hidden.attr('disabled','disabled');  
  ['qemu', 'lxc'].forEach(function(type){
    fieldsets(type).forEach(function(id){
      toggleFieldset(id, fieldset, fieldset.selected, type);
    });
  });
}

function nodeSelected(item) {
  var node_id = $(item).val();
  var type = $("#host_compute_attributes_type").val();
  if (type == undefined) type = $("#compute_attribute_vm_attrs_type").val();
  switch (type) {
    case 'qemu':
      updateOptions('isostorages', 'compute_attributes_config_attributes', 'cdrom_storage', 'compute_attributes_config_attributes', 'cdrom_iso', 'storage', node_id, undefined);
      updateOptions('storages', 'compute_attributes_volumes_attributes', 'storage', undefined, undefined, 'storage', node_id, undefined);
      updateOptions('bridges', 'interfaces_attributes', 'compute_attributes_bridge', undefined, undefined, 'iface', node_id, undefined);
      break;
    case 'lxc':
      updateOptions('ostemplates', 'compute_attributes_ostemplate', 'storage', 'compute_attributes_ostemplate', 'file', 'storage', node_id, undefined);
      updateOptions('storages', 'compute_attributes_volumes_attributes', 'storage', undefined, undefined, 'storage', node_id, undefined);
      updateOptions('bridges', 'interfaces_attributes', 'compute_attributes_bridge', undefined, undefined, 'iface', node_id, undefined);
      break;
    default:
      console.log("unkown type=" + type);
      break;
  }
}

function emptySelect(select){
  $(select).empty();
  $(select).append($("<option></option>").val('').text(''));
  $(select).val('');
}

function initOptions(select_ids){
  console.log('initOptions(' + select_ids[0] + ')');
  select_ids.forEach(emptySelect);
  select_ids.forEach(function(select){
    $(select + ' option:selected').prop('selected',false);
    $(select).val('');
  });
}

function updateOption(select_id, option, option_id){
  console.log('update '+ select_id + ' with '+ option[option_id]);
  $(select_id).append($('<option></option>').val(option[option_id]).text(option[option_id]));
}

function selectIds(start_options_id, end_options_id){
  var select_host_id = 'select[id^=host_' + start_options_id + ']';
  var compute_attributes_regex = /compute_attributes_/gi;
  var select_profile_id = 'select[id^=compute_attribute_vm_attrs_' + start_options_id.replace(compute_attributes_regex, '') + ']';
  if (end_options_id != undefined) {
    select_host_id += '[id$=' + end_options_id + ']';
    select_profile_id += '[id$=' + end_options_id.replace(compute_attributes_regex, '') + ']';
  }
  return [select_host_id, select_profile_id];
}

function updateOptions(options_path, start_options_id, end_options_id, start_second_options_id, end_second_options_id, option_id, node_id, second_id) {
  
  var select_ids = selectIds(start_options_id, end_options_id);
  var select_second_ids;
  if ( start_second_options_id != undefined && end_second_options_id != undefined) {
    select_second_ids = selectIds(start_second_options_id, end_second_options_id);
  }
  var compute_resource_id = $("#host_compute_resource_id").val();
  if (compute_resource_id == undefined) compute_resource_id = $("#compute_attribute_compute_resource_id").val(); // profil
  var url = '/foreman_fog_proxmox/' + options_path +  '/' + compute_resource_id +  '/' + node_id;
  if (second_id != undefined) url += '/' + second_id;
  tfm.tools.showSpinner();
  $.getJSON({
    type: 'get',
    url: url,
    error: function(j,status,error){
      var errorMsg = 'Error=' + error + ', status=' + status + ' loading ' + options_path + ' for node_id=' + node_id;
      if (second_id != undefined) errorMsg += ' and second_id=' + second_id;
      console.log(errorMsg);
    },
    success: function(options) {
      initOptions(select_ids);
      if (select_second_ids != undefined) {
        initOptions(select_second_ids);
      }
      $.each(options, function(i,option){
        for (var j = 0; j < select_ids.length; j++) {
          updateOption(select_ids[j], option, option_id);
        }
      });
    },
    complete: function(item){
      // eslint-disable-next-line no-undef
      reloadOnAjaxComplete(item);
      tfm.tools.hideSpinner();
    }
  });
}
