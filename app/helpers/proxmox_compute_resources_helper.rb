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

module ProxmoxComputeResourcesHelper
  def user_token_expiration_date(compute_resource)
    expire = compute_resource.current_user_token_expire
  rescue ::Foreman::Exception => e
    'Has already expired. Please edit the compute resource to set a new valid one.' if e.message == 'User token expired'
  rescue StandardError => e
    logger.warn("failed to get identity client version: #{e}")
    raise e
  else
    return 'Never' if expire == 0

    Time.at(expire).utc
  end

  def cluster_nodes(compute_resource)
    nodes = compute_resource.nodes ? compute_resource.nodes.collect(&:node) : []
  rescue ::Foreman::Exception => e
    [] if e.message == 'User token expired'
  rescue StandardError => e
    logger.warn("failed to get cluster nodes: #{e}")
    raise e
  else
    nodes
  end

  def proxmox_auth_methods_map
    [OpenStruct.new(id: 'access_ticket', name: '(Default) Access ticket'),
     OpenStruct.new(id: 'user_token', name: 'User token')]
  end
end
