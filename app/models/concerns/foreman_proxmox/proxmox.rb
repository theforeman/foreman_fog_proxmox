# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanProxmox.

# ForemanProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanProxmox. If not, see <http://www.gnu.org/licenses/>.

require 'fog/proxmox'

module ForemanProxmox
  class Proxmox < ComputeResource
    validates :url, :user, :password, :presence => true
    attr_accessor :node

    def provided_attributes
      super.merge(
        :uuid => :reference,
        :mac  => :mac
      )
    end

    def capabilities
      [:build]
    end

    def find_vm_by_uuid(vmid)
      node.servers.get(vmid)
    rescue Fog::Errors::Error => e
      Foreman::Logging.exception("Failed retrieving proxmox vm by vmid #{vmid}", e)
      raise(ActiveRecord::RecordNotFound) if e.message.include?('HANDLE_INVALID')
      raise(ActiveRecord::RecordNotFound) if e.message.include?('VM.get_record: ["SESSION_INVALID"')
      raise e
    end

    # we default to destroy the VM's storage as well.
    def destroy_vm(ref, args = {})
      logger.info "destroy_vm: #{ref} #{args}"
      find_vm_by_uuid(ref).destroy
    rescue ActiveRecord::RecordNotFound
      true
    end

    def self.model_name
      ComputeResource.model_name
    end

    def credentials_valid?
      errors[:url].empty? && errors[:user].empty? && errors[:user].include?('@') && errors[:password].empty? && hypervisor
    end

    def test_connection(options = {})
      super
      credentials_valid?
    rescue StandardError => e
      begin
        disconnect
      rescue StandardError
        nil
      end
      errors[:base] << e.message
    end

    def available_nodes
      read_from_cache('available_nodes', 'available_nodes!')
    end

    def available_nodes!
      store_in_cache('available_nodes') do
        nodes = client.nodes.all
        nodes.sort_by(&:node)
      end
    end

    def available_storages
      read_from_cache('available_storages', 'available_storages!')
    end

    def available_storages!
      store_in_cache('available_storages') do
        storages = client.storages.all
        storages.sort_by(&:storage)
      end
    end

    def associated_host(vm)
      associate_by('node', vm.node)
    end

    def new_vm(attr = {})
      test_connection
      return unless errors.empty?
      opts = vm_instance_defaults.merge(attr.to_hash).symbolize_keys

      %i[networks volumes].each do |collection|
        nested_attrs     = opts.delete("#{collection}_attributes".to_sym)
        opts[collection] = nested_attributes_for(collection, nested_attrs) if nested_attrs
      end
      opts.reject! { |_, v| v.nil? }
      client.servers.new opts
    end

    def create_vm(args = {})
      node = get_cluster_node(args)
      logger.info "create_vm(): node: #{node.node}"
      node.servers.create(args)
    rescue StandardError => e
      logger.info e
      logger.info e.backtrace.join("\n")
      false
    end

    def next_vmid
      node = get_cluster_node
      node.servers.next_id
    end

    protected

    def client
      @client ||= ::Fog::Compute::Proxmox.new(
        pve_url: url,
        pve_username: user,
        pve_password: password,
        connection_options: { disable_proxy: true, ssl_verify_peer: false } # dev tests only
      )
    end

    def disconnect
      client.terminate if @client
      @client = nil
    end

    def vm_instance_defaults
      super.merge({})
    end

    private

    def get_cluster_node(args = {})
      return client.nodes.all.first unless args[:cluster_node] != ''
      client.nodes.find_by_id(args[:cluster_node])
    end

    def read_from_cache(key, fallback)
      value = Rails.cache.fetch(cache_key + key) { public_send(fallback) }
      value
    end

    def store_in_cache(key)
      value = yield
      Rails.cache.write(cache_key + key, value)
      value
    end

    def cache_key
      "computeresource_#{id}/"
    end
  end
end
