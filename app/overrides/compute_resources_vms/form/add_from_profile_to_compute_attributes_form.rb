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
  virtual_path: 'compute_attributes/_compute_form',
  name: 'remove_networks_and_volumes_partial',
  remove: "erb[loud]:contains('compute_resources_vms/form/networks'), erb[loud]:contains('compute_resources_vms/form/volumes')"
)

Deface::Override.new(
  :virtual_path => 'compute_attributes/_form',
  :name => 'add_from_profile_to_compute_attributes_form',
  :replace => "erb[loud]:contains('render')",
  :partial => 'compute_resources_vms/form/proxmox/add_from_profile_to_compute_attributes_form',
  :original => '0e01b2f93b6855afc207e0e301515cdd300a1c61',
  :namespaced => true
)

Deface::Override.new(
  :virtual_path => 'compute_attributes/_compute_form',
  :name => 'add_from_profile_to_compute_form',
  :replace => "erb[loud]:contains('provider_partial')",
  :partial => 'compute_resources_vms/form/proxmox/add_from_profile_to_compute_form',
  :original => '107f930f8e6b2bdd3e728757d8320d483f19ff9e',
  :namespaced => true
)
