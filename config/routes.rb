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

Rails.application.routes.draw do
  namespace :foreman_fog_proxmox do
    match 'isos/:node_id/:storage', :to => 'compute_resources#isos_by_node_and_storage', :via => 'get'
    match 'ostemplates/:node_id/:storage', :to => 'compute_resources#ostemplates_by_node_and_storage', :via => 'get'
    match 'isos/:node_id', :to => 'compute_resources#isos_by_node', :via => 'get'
    match 'ostemplates/:node_id', :to => 'compute_resources#ostemplates_by_node', :via => 'get'
    match 'storages/:node_id', :to => 'compute_resources#storages_by_node', :via => 'get'
    match 'isostorages/:node_id', :to => 'compute_resources#iso_storages_by_node', :via => 'get'
    match 'bridges/:node_id', :to => 'compute_resources#bridges_by_node', :via => 'get'
  end
end
