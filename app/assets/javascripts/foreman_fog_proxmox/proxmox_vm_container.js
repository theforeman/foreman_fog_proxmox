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


function storageOstemplateSelected(item) {
  var storage = $(item).val();
  var node_id = $('#host_compute_attributes_node_id').val();
  if (node_id == undefined) node_id = $("#compute_attribute_vm_attrs_node_id").val();
  if (storage != '') {
    tfm.tools.showSpinner();
    $.getJSON({
      type: 'get',
      url: '/foreman_fog_proxmox/ostemplates/' + node_id + '/' + storage,
      complete: function(){
        tfm.tools.hideSpinner();
      },
      error: function(j,status,error){
        console.log("Error=" + error +", status=" + status + " loading os templates for storage=" + storage + " and node_id=" + node_id);
      },
      success: function(ostemplates) {
        initOstemplateOptions();
        $.each(ostemplates, function(i,ostemplate){
          $('#host_compute_attributes_ostemplate_file').append($("<option></option>").val(ostemplate.volid).text(ostemplate.volid));
          $('#compute_attribute_vm_attrs_ostemplate_file').append($("<option></option>").val(ostemplate.volid).text(ostemplate.volid));
        });
      },
      complete: function(item){
        // eslint-disable-next-line no-undef
        reloadOnAjaxComplete(item);
      }
    });
  } else {
    initOstemplateOptions();
  }
}