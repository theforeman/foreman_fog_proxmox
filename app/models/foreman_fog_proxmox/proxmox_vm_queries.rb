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
  module ProxmoxVMQueries
    include ProxmoxPools
    include ProxmoxVMUuidHelper

    def nodes
      client ? Array(client.nodes.all).sort_by(&:node) : []
    end

    def node_availability
      available, offline = nodes.partition { |node| !offline_node?(node) }

      { available: available, offline: offline }
    end

    def available_nodes
      node_availability[:available]
    end

    def offline_nodes
      node_availability[:offline]
    end

    def storages(node_id = default_node_id, type = 'images')
      node = client.nodes.get node_id
      node ||= default_node
      storages = type ? node.storages.list_by_content_type(type) : node.storages.all
      logger.debug("storages(): node_id #{node_id} type #{type}")
      storages.reject { |s| s.enabled.to_i.zero? || s.active.to_i.zero? }.sort_by(&:storage)
    end

    def bridges(node_id = default_node_id)
      node = network_client.nodes.get node_id
      node ||= network_client.nodes.first
      bridges = node.networks.all(type: 'any_bridge')
      bridges.sort_by(&:iface)
    end

    # TODO: Pagination with filters
    def vms(opts = {})
      vms = []
      available_nodes.each { |node| vms += node.servers.all + node.containers.all }
      vms.each { |vm| attach_compute_resource_id(vm) }
      if opts.key?(:eager_loading) && opts[:eager_loading]
        vms_eager = []
        vms.each { |vm| vms_eager << attach_compute_resource_id(vm.collection.get(vm.identity)) }
        vms = vms_eager
      end
      ForemanFogProxmox::Vms.new(vms)
    end

    def find_vm_by_uuid(uuid)
      vmid = extract_vmid(uuid)
      return nil if ForemanFogProxmox::Value.empty?(vmid)

      availability = node_availability
      availability[:available].each do |node|
        vm = find_vm_in_servers_by_vmid(node.servers, vmid)
        vm ||= find_vm_in_servers_by_vmid(node.containers, vmid)
        next if vm.nil?
        logger.debug("found vm #{vmid} on node #{node.node}")
        return vm
      end

      unless availability[:offline].empty?
        raise ::Foreman::Exception,
          format(_('Unable to locate Proxmox VM %<vmid>s: nodes %<nodes>s were offline and were not searched'),
            vmid: vmid, nodes: availability[:offline].map(&:node).join(', '))
      end
      nil
    end

    def find_vm_in_servers_by_vmid(servers, vmid)
      vm = begin
        servers.get(vmid) unless ForemanFogProxmox::Value.empty?(vmid)
      rescue Fog::Errors::NotFound
        nil
      end
      pool_owner(vm) if vm
      attach_compute_resource_id(vm)
    rescue StandardError => e
      Foreman::Logging.exception(format(_('Failed retrieving proxmox server vm by vmid=%<vmid>s'), vmid: vmid), e)
      raise ::Foreman::Exception,
        format(_('Failed retrieving Proxmox VM %<vmid>s: %<error>s'), vmid: vmid, error: e.message)
    end

    private

    def offline_node?(node)
      node.respond_to?(:status) && node.status == 'offline'
    end

    def attach_compute_resource_id(virtual_machine)
      return virtual_machine if virtual_machine.nil?

      virtual_machine.compute_resource_id = id if virtual_machine.respond_to?(:compute_resource_id=)
      virtual_machine
    end
  end
end
