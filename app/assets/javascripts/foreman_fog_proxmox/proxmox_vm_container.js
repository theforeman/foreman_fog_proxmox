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

function initOstemplateStorage(){
    var select = '#host_compute_attributes_ostemplate_storage';
    $(select + ' option:selected').prop('selected',false);
    $(select).val('');
  }
  
  function initOstemplateOptions(){
    var select = '#host_compute_attributes_ostemplate_file';
    $(select).empty();
    $(select).append($("<option></option>").val('').text(''));
    $(select).val('');
  }


function storageOstemplateSelected(item) {
    var storage = $(item).val();
    if (storage != '') {
      tfm.tools.showSpinner();
      $.getJSON({
        type: 'get',
        url: '/foreman_fog_proxmox/ostemplates/'+storage,
        complete: function(){
          tfm.tools.hideSpinner();
        },
        error: function(j,status,error){
          console.log("Error=" + error +", status=" + status + " loading os templates for storage=" + storage);
        },
        success: function(ostemplates) {
          initOstemplateOptions();
          $.each(ostemplates, function(i,ostemplate){
            $('#host_compute_attributes_ostemplate_file').append($("<option></option>").val(ostemplate.volid).text(ostemplate.volid));
          });
        }
      });
    } else {
      initOstemplateOptions();
    }
  }