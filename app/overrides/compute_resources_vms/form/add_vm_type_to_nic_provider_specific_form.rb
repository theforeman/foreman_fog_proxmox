# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

Deface::Override.new(
  :virtual_path => 'nic/_provider_specific_form',
  :name => 'add_vm_type_to_nic_provider_specific_form',
  :replace => "erb[loud]:contains('f.fields_for')",
  :closing_selector => "erb[silent]:contains('end')",
  :partial => 'compute_resources_vms/form/proxmox/add_vm_type_to_nic_provider_specific_form',
  :original => 'f1a2373efd9c7c993fd1662a2ee4752183542704'
)
