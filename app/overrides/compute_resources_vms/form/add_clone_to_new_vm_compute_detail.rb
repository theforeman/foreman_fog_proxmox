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
  :virtual_path => 'hosts/_compute_detail',
  :name => 'add_from_profile_to_compute_detail',
  :replace => "erb[loud]:contains('provider_partial')",
  :partial => 'compute_resources_vms/form/proxmox/add_from_profile_to_hosts_compute_detail_form',
  :original => '448e3b265e4dc1789f0efbbc6076e32216ac3a24',
  :namespaced => true
)
