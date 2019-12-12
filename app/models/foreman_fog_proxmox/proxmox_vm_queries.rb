# frozen_string_literal: true

# Copyright 2019 Tristan Robert

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

module ForemanFogProxmox
  module ProxmoxVmQueries
    def next_vmid
      node.servers.next_id
    end

    def nodes
      nodes = client.nodes.all if client
      nodes&.sort_by(&:node)
    end

    def pools
      pools = identity_client.pools.all
      pools.sort_by(&:poolid)
    end

    def storages(type = 'images')
      storages = node.storages.list_by_content_type type
      storages.sort_by(&:storage)
    end

    def bridges
      node = network_client.nodes.get node_id
      bridges = node.networks.all(type: 'any_bridge')
      bridges.sort_by(&:iface)
    end

    def vms(_opts = {})
      node
    end

    def find_vm_by_uuid(uuid)
      # look for the uuid on all known nodes
      vm = nil
      nodes.each do |node|
        vm = find_vm_in_servers_by_uuid(node.servers, uuid)
        vm ||= find_vm_in_servers_by_uuid(node.containers, uuid)
        unless vm.nil?
          logger.debug("found vm #{uuid} on node #{node.node}")
          break
        end
      end
      vm
    end

    def find_vm_in_servers_by_uuid(servers, uuid)
      servers.get(uuid) if uuid != nil && !uuid.to_s.empty?
    rescue Fog::Errors::NotFound
      nil
    rescue StandardError => e
      Foreman::Logging.exception(format(_('Failed retrieving proxmox server vm by vmid=%<vmid>s'), vmid: uuid), e)
      raise(ActiveRecord::RecordNotFound)
    end
  end
end
