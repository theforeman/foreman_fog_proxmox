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
  disableFieldset(selected,'advanced_options',true);
  var fieldsets = ['options','cpu','memory','cdrom','os','dns'];
  for (i=0;i<fieldsets.length;i++){
    toggleFieldset(selected,fieldsets[i],false);
  }

  return false;
}

function disableFieldset(selected,fieldset,toggle){
  var server_fieldset = $('#server_config_'+fieldset);
  var container_fieldset = $('#container_config_'+fieldset);
  switch (selected) {
    case 'qemu':
      if (toggle){
        server_fieldset.toggle();
        container_fieldset.toggle();
      }
      server_fieldset.removeAttr('disabled');
      container_fieldset.attr('disabled','disabled');
      break;
    case 'lxc':
      if (toggle){
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
