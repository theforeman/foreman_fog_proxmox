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

function vmTypeSelected(item) {
  var selected = $(item).val();
  var fieldsets = [];
  fieldsets.push({id: 'general', toggle: true, selected: selected});
  fieldsets.push({id: 'config_advanced_options', toggle: true, selected: selected});
  fieldsets.push({id: 'config_ext', toggle: true, selected: selected});
  fieldsets.push({id: 'volume', toggle: true, selected: selected});
  fieldsets.push({id: 'network', toggle: true, selected: selected});
  fieldsets.push({id: 'config_options', toggle: false, selected: selected});
  fieldsets.push({id: 'config_cpu', toggle: false, selected: selected});
  fieldsets.push({id: 'config_memory', toggle: false, selected: selected});
  fieldsets.push({id: 'config_cdrom', toggle: false, selected: selected});
  fieldsets.push({id: 'config_os', toggle: false, selected: selected});
  fieldsets.push({id: 'config_dns', toggle: false, selected: selected});
  fieldsets.forEach(toggleFieldset);
  return false;
}

function toggleFieldset(fieldset, index, fieldsets){
  var server_fieldset = $("fieldset[id^='server_"+fieldset.id+"']");
  var container_fieldset = $("fieldset[id^='container_"+fieldset.id+"']");
  switch (fieldset.selected) {
    case 'qemu':
      if (fieldset.toggle){
        server_fieldset.toggle();
        container_fieldset.toggle();
      }
      server_fieldset.removeAttr('disabled');
      container_fieldset.attr('disabled','disabled');
      break;
    case 'lxc':
      if (fieldset.toggle){
        server_fieldset.toggle();
        container_fieldset.toggle();
      }
      server_fieldset.attr('disabled','disabled');
      container_fieldset.removeAttr('disabled');
      break;
    default:
      break;
  }
}
