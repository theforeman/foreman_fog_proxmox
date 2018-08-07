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
  }
}

function toggleFieldset(fieldset, index, fieldsets){
  console.log("fieldset.id="+fieldset.id);
  console.log("fieldset.toggle="+fieldset.toggle);
  console.log("fieldset.new_vm="+fieldset.new_vm);
  var server_input_hidden = $("div[id^='server_volumes']" + " > input:hidden");
  var container_input_hidden = $("div[id^='container_volumes']" + " > input:hidden");
  var server_fieldset = $("fieldset[id^='server_"+fieldset.id+"']");
  var container_fieldset = $("fieldset[id^='container_"+fieldset.id+"']");
  switch (fieldset.selected) {
    case 'qemu':
      if (fieldset.toggle && fieldset.new_vm){
        console.log("toggle qemu fieldset.id="+fieldset.id);
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
        console.log("toggle lxc fieldset.id="+fieldset.id);
        server_fieldset.hide();
        container_fieldset.show();
      }
      server_fieldset.attr('disabled','disabled');
      container_fieldset.removeAttr('disabled');
      container_input_hidden.removeAttr('disabled');
      server_input_hidden.attr('disabled','disabled');
      break;
    default:
      break;
  }
}
