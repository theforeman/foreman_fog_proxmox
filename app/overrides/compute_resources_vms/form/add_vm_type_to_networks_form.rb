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
    :virtual_path => "compute_resources_vms/form/_networks",
    :name => "add_vm_type_to_networks_form",
    :replace => "erb[loud]:contains('render')",
    :partial => "compute_resources_vms/form/proxmox/add_vm_type_to_networks_form",
    :original => 'bae57f59cbbf6fcf1aecdf3a02baee5ff3494c85'
)

Deface::Override.new(
    :virtual_path => "compute_resources_vms/form/_networks",
    :name => "add_vm_type_to_networks_new_childs_form",
    :replace => "erb[loud]:contains('new_child_fields_template')",
    :partial => "compute_resources_vms/form/proxmox/add_vm_type_to_networks_new_childs_form",
    :original => '4ba200e5e02810ade03827374de9b0b8b6a2f6a9' 
)