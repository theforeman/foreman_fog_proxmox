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
      cached_nodes = cache.cache(:nodes) do
        nodes = client.nodes.all if client
        nodes&.sort_by(&:node)&.map do |node|
          { node: node.node }
        end
      end

      structs_from_cache(cached_nodes)
    end

    def storages(node_id = default_node_id, type = 'images')
      cached_storages = cache.cache(:"storages-#{node_id}-#{type}") do
        node = client.nodes.get(node_id) || default_node
        storages = node.storages.list_by_content_type type
        logger.debug("storages(): node_id #{node_id} type #{type}")
        storages.reject { |s| s.enabled.to_i.zero? || s.active.to_i.zero? }.sort_by(&:storage).map do |storage|
          fields = [:storage, :enabled, :active, :content, :node_id, :avail, :used, :total]
          extract_attributes(storage, fields).merge(identity: storage.storage)
        end
      end

      structs_from_cache(cached_storages)
    end

    def bridges(node_id = default_node_id)
      cached_bridges = cache.cache(:"bridges-#{node_id}") do
        node = network_client.nodes.get node_id
        node ||= network_client.nodes.first
        bridges = node.networks.all(type: 'any_bridge')
        bridges.sort_by(&:iface).map do |bridge|
          extract_attributes(bridge, [:iface, :node_id]).merge(identity: bridge.iface)
        end
      end

      structs_from_cache(cached_bridges)
    end

    # TODO: Pagination with filters
    def vms(opts = {})
      vms = []
      fog_nodes.each { |node| vms += node.servers.all + node.containers.all }
      vms.each { |vm| attach_compute_resource_id(vm) }
      if opts.key?(:eager_loading) && opts[:eager_loading]
        vms_eager = []
        vms.each { |vm| vms_eager << attach_compute_resource_id(vm.collection.get(vm.identity)) }
        vms = vms_eager
      end
      ForemanFogProxmox::Vms.new(vms)
    end

    def find_vm_by_uuid(uuid)
      # look for the uuid on all known nodes
      vm = nil
      vmid = extract_vmid(uuid)
      fog_nodes.each do |node|
        vm = find_vm_in_servers_by_vmid(node.servers, vmid)
        vm ||= find_vm_in_servers_by_vmid(node.containers, vmid)
        next if vm.nil?
        logger.debug("found vm #{vmid} on node #{node.node}")
        break
      end
      vm
    end

    def find_vm_in_servers_by_vmid(servers, vmid)
      vm = servers.get(vmid) unless ForemanFogProxmox::Value.empty?(vmid)
      pool_owner(vm) if vm
      attach_compute_resource_id(vm)
    rescue Fog::Errors::NotFound
      nil
    rescue StandardError => e
      Foreman::Logging.exception(format(_('Failed retrieving proxmox server vm by vmid=%<vmid>s'), vmid: vmid), e)
      raise(ActiveRecord::RecordNotFound, e)
    end

    private

    def fog_nodes
      nodes = client.nodes.all if client
      nodes&.sort_by(&:node) || []
    end

    def attach_compute_resource_id(virtual_machine)
      return virtual_machine if virtual_machine.nil?

      virtual_machine.compute_resource_id = id if virtual_machine.respond_to?(:compute_resource_id=)
      virtual_machine
    end
  end
end
