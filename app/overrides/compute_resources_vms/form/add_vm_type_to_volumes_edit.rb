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
    :virtual_path => "compute_resources_vms/form/_volumes",
    :name => "add_vm_type_to_volumes_edit",
    :replace_contents => "div.children_fields",
    :partial => "compute_resources_vms/form/proxmox/add_vm_type_to_volumes_edit",
    :original => '741194531465d567107d762aa11de9d00628c841'
)