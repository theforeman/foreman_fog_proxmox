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
  updateOptions('ostemplates', 'compute_attributes_ostemplate', 'file', undefined, undefined, 'volid', node_id, storage);
}

function setDisabled($el, disabled) {
  if (!$el || !$el.length) return;
  $el.prop('disabled', disabled);
  $el.toggleClass('disabled', disabled);
}

function syncDhcpIPv4(item) {
  var $dhcp = $(item);
  var checked = $dhcp.is(':checked');
  var $fieldset = $dhcp.closest('fieldset');
  var $cidr = $fieldset.find('input.proxmox-cidr-ipv4').first();
  var $gw = $fieldset.find('input.proxmox-gw-ipv4').first();

  setDisabled($cidr, !checked);
  setDisabled($gw, !checked);
}

function syncDhcpIPv6(item) {
  var $dhcp6 = $(item);
  var checked = $dhcp6.is(':checked');
  var $fieldset = $dhcp6.closest('fieldset');
  var $cidr6 = $fieldset.find('input.proxmox-cidr-ipv6').first();
  var $gw6 = $fieldset.find('input.proxmox-gw-ipv6').first();

  setDisabled($cidr6, !checked);
  setDisabled($gw6, !checked);
}

function dhcpIPv4Selected(item) {
  syncDhcpIPv4(item);
}

function dhcpIPv6Selected(item) {
  syncDhcpIPv6(item);
}

function syncAllProxmoxDhcpFields() {
  $('input.proxmox-dhcp-ipv4').each(function() {
    syncDhcpIPv4(this);
  });

  $('input.proxmox-dhcp-ipv6').each(function() {
    syncDhcpIPv6(this);
  });
}

$(document).on('turbolinks:load', function() {
  syncAllProxmoxDhcpFields();
});