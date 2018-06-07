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
    has_one :config
    validates :url, :user, :password, :presence => true

    def provided_attributes
      super.merge(
        :uuid => :reference,
        :mac  => :mac
      )
    end

    def capabilities
      [:build]
    end

    def find_vm_by_uuid(uuid)
      node.servers.get(uuid)
    rescue Fog::Errors::Error => e
      Foreman::Logging.exception("Failed retrieving proxmox vm by vmid #{uuid}", e)
      raise(ActiveRecord::RecordNotFound) if e.message.include?('HANDLE_INVALID')
      raise(ActiveRecord::RecordNotFound) if e.message.include?('VM.get_record: ["SESSION_INVALID"')
      raise e
    end

    def self.model_name
      ComputeResource.model_name
    end

    def credentials_valid?
      errors[:url].empty? && errors[:user].empty? && errors[:user].include?('@') && errors[:password].empty?
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

    def nodes
      nodes = client.nodes.all
      nodes.sort_by(&:node)
    end

    def pools
      pools = identity_client.pools.all
      pools.sort_by(&:poolid)
    end

    def storages
      storages = client.storages.all
      storages.sort_by(&:storage)
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
      node.servers.new(vmid: next_vmid, memory: 512, cores: 1, sockets: 1, cpu: 'kvm64')
    end

    def create_vm(args = {})
      raise ::Foreman::Exception.new N_("invalid vmid") unless node.servers.id_valid?(args[:vmid])
      super(args)
      vm = node.servers.get(args[:vmid])
      vm
    rescue => e
      logger.warn "failed to create vm: #{e}"
      destroy_vm vm.id if vm
      volume_client.volumes.delete(@boot_vol_id) if args[:boot_from_volume]
      raise message
    end

    def next_vmid
      node.servers.next_id
    end

    protected

    def fog_credentials
      { pve_url: url,
        pve_username: user,
        pve_password: password,
        connection_options: { disable_proxy: true, ssl_verify_peer: false } } # dev tests only
    end

    def client
      @client ||= ::Fog::Compute::Proxmox.new(fog_credentials)
    end

    def identity_client
      @identity_client ||= ::Fog::Identity::Proxmox.new(fog_credentials)
    end

    def disconnect
      client.terminate if @client
      @client = nil
    end

    def vm_instance_defaults
      super.merge({})
    end

    private

    def node
      get_cluster_node
    end

    def get_cluster_node(args = {})
      return client.nodes.first unless !args.empty? && args[:cluster_node] != ''
      client.nodes.find_by(id: args[:cluster_node])
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
