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

$(document).ready(function () {
  sslVerifyPeerSelected();
  authMethodSelected();
});

function sslVerifyPeerSelected() {
  var selected = $("#compute_resource_ssl_verify_peer").is(':checked');
  var ssl_certs_block = $('#compute_resource_ssl_certs').parents('.clearfix');
  var ssl_certs_textarea = $('#compute_resource_ssl_certs');
  if (selected) {
    ssl_certs_block.show();
    ssl_certs_textarea.show();
  } else {
    ssl_certs_block.hide();
    ssl_certs_textarea.text('');
    ssl_certs_textarea.hide();
  }
}

function authMethodSelected() {
  var selected = $("#compute_resource_auth_method").val();
  console.log("auth_method="+selected);
  var compute_ressource_user_token_field_set = $('#compute_ressource_user_token_field_set');
  var compute_ressource_access_ticket_field_set = $('#compute_ressource_access_ticket_field_set');
  if (selected == 'user_token') {
    compute_ressource_user_token_field_set.show();
    compute_ressource_user_token_field_set.removeAttr('disabled');
    compute_ressource_access_ticket_field_set.hide();
    compute_ressource_access_ticket_field_set.attr('disabled','disabled');
  } else {
    compute_ressource_access_ticket_field_set.show();
    compute_ressource_access_ticket_field_set.removeAttr('disabled');
    compute_ressource_user_token_field_set.hide();
    compute_ressource_user_token_field_set.attr('disabled','disabled');
  }
}