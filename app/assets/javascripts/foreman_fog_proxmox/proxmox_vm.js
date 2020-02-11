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
  fieldsets.forEach(toggleFieldset);
  toggleVolumes(selected);
  return false;
}

function toggleVolumes(selected){
  var div_container = $("div[id^='container_volumes']");
  var div_server = $("div[id^='server_volumes']");
  var a_container = $("a[data-association='container_volumes']");
  var a_server = $("a[data-association='server_volumes']");
  switch (selected) {
    case 'qemu':
      div_container.hide();
      div_server.show();
      a_container.hide();
      a_server.show();
      break;
    case 'lxc':
      div_container.show();
      div_server.hide();
      a_container.show();
      a_server.hide();
      break;
    default:
      console.log("unkown type="+selected);
      break;
  }
}

function toggleFieldset(fieldset, index, fieldsets){
  var server_input_hidden = $("div[id^='server_volumes']" + " + input:hidden");
  var container_input_hidden = $("div[id^='container_volumes']" + " + input:hidden");
  var removable_input_hidden = $("div.removable-item[style='display: none;']" + " + input:hidden");
  var server_fieldset = $("fieldset[id^='server_"+fieldset.id+"']");
  var container_fieldset = $("fieldset[id^='container_"+fieldset.id+"']");
  removable_input_hidden.attr('disabled','disabled');
  switch (fieldset.selected) {
    case 'qemu':
      if (fieldset.toggle && fieldset.new_vm){
        server_fieldset.show();
        container_fieldset.hide();
      }
      server_fieldset.removeAttr('disabled');
      container_fieldset.attr('disabled','disabled');
      server_input_hidden.removeAttr('disabled');
      container_input_hidden.attr('disabled','disabled');
      break;
    case 'lxc':
      if (fieldset.toggle && fieldset.new_vm){
        server_fieldset.hide();
        container_fieldset.show();
      }
      server_fieldset.attr('disabled','disabled');
      container_fieldset.removeAttr('disabled');
      container_input_hidden.removeAttr('disabled');
      server_input_hidden.attr('disabled','disabled');
      break;
    default:
      console.log("unkown type="+fieldset.selected);
      break;
  }
}

function nodeSelected(item) {
  var node_id = $(item).val();
  var type = $("#host_compute_attributes_type").val();
  if (type == undefined) type = $("#compute_attribute_vm_attrs_type").val();
  switch (type) {
    case 'qemu':
      updateOptions('isostorages', 'compute_attributes_config_attributes', 'cdrom_storage', 'compute_attributes_config_attributes', 'cdrom_iso', 'storage', node_id);
      updateOptions('storages', 'compute_attributes_volumes_attributes', 'storage', undefined, undefined, 'storage', node_id);
      updateOptions('bridges', 'interfaces_attributes', 'compute_attributes_bridge', undefined, undefined, 'iface', node_id);
      break;
    case 'lxc':
      updateOptions('ostemplates', 'compute_attributes_ostemplate', 'storage', 'compute_attributes_ostemplate', 'file', 'storage', node_id);
      updateOptions('storages', 'compute_attributes_volumes_attributes', 'storage', undefined, undefined, 'storage', node_id);
      updateOptions('bridges', 'interfaces_attributes', 'compute_attributes_bridge', undefined, undefined, 'iface', node_id);
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

function updateOptions(options_path, start_options_id, end_options_id, start_second_options_id, end_second_options_id, option_id, node_id, second_id = undefined) {
  
  var select_ids = selectIds(start_options_id, end_options_id);
  var select_second_ids;
  if ( start_second_options_id != undefined && end_second_options_id != undefined) {
    select_second_ids = selectIds(start_second_options_id, end_second_options_id);
  }
  var url = '/foreman_fog_proxmox/' + options_path +  '/' + node_id;
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
