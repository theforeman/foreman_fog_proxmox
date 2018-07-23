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

# Displays Proxmox vm type select tab on Host form

Deface::Override.new(
        :virtual_path => 'hosts/_form',
        :name => 'vm_type_tab',
        :insert_after => 'li.active',
        :partial => 'foreman_fog_proxmox/vm_type/select_tab_title'
)
      
Deface::Override.new(
        :virtual_path => 'hosts/_form',
        :name => 'vm_type_tab_content',
        :insert_after => 'div.tab-pane.active',
        :partial => 'foreman_fog_proxmox/vm_type/select_tab_content'
)