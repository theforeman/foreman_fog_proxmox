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
        :mac  => :mac
      )
    end
    
    def self.provider_friendly_name
      "Proxmox"
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
      storages = node.storages.all
      storages.sort_by(&:storage)
    end

    def associated_host(vm)
      associate_by('node', vm.node)
    end

    def new_vm(attr = {})
      test_connection
      node.servers.new(vm_instance_defaults.merge(attr.to_hash.deep_symbolize_keys)) if errors.empty?
    end

    def create_vm(args = {})
      raise ::Foreman::Exception.new N_("invalid vmid") unless node.servers.id_valid?(args[:vmid])
      node = get_cluster_node args
      logger.debug("create_vm(): #{args}")
      node.servers.create(parse_vm(args))
      vm = node.servers.get(args[:vmid])
      vm
    rescue => e
      logger.warn "failed to create vm: #{e}"
      destroy_vm vm.id if vm
      raise e
    end

    def parse_vm(args)
      config = args['config']
      volumes = parse_volume(args['volumes'])
      cpu = parse_cpu(args.reject { |key,_value| !['cpu_type','spectre','pcid'].include? key })
      memory = parse_memory(args.reject { |key,_value| !['memory','min_memory','balloon','shares'].include? key })
      args = args.reject { |key,_value| ['node','config','volumes','interfaces_attributes','firmware_type','provision_method'].include? key }
      args = args.merge(config)
      args = args.merge(volumes)
      args = args.merge(cpu)
      args = args.merge(memory)
      logger.debug("parse_vm(): #{args}")
      args
    end

    def parse_memory(args)
      memory = {memory: args['cpu_type'].to_i}
      ballooned = args['balloon'].to_i
      if ballooned
        memory.store(:shares,args['shares'].to_i)
        memory.store(:balloon,args['min_memory'].to_i)
      else
        memory.store(:balloon,ballooned)
      end
      memory
    end

    def parse_cpu(args)
      cpu = "cputype=#{args['cpu_type']}"
      spectre = args['spectre'].to_i
      pcid = args['pcid'].to_i
      cpu += ",flags=" if spectre || pcid
      cpu += "+spec-ctrl" if spectre
      cpu += ";" if spectre && pcid
      cpu += "+pcid" if pcid
      { cpu: cpu }
    end

    def parse_volume(args)
      disk = {}
      id = "#{args['bus']}#{args['device']}"
      delete = args['_delete'].to_i == 1
      if delete
        logger.debug("parse_volumes(): delete id=#{id}")
        disk.store(:delete, id)
        disk
      else
        disk.store(:id, id)
        disk.store(:storage, "#{args['storage']}")
        disk.store(:size, "#{args['size']}")
        options = args.reject { |key,_value| ['bus','device','storage','size','_delete'].include? key}
        logger.debug("parse_volume(): add disk=#{disk}, options=#{options}")
        Fog::Proxmox::Disk.flatten(disk,Fog::Proxmox::Hash.stringify(options))
      end 
    end

    def next_vmid
      node.servers.next_id
    end

    def new_volume(attr = {})
      storages = node.storages.list_by_content_type 'images'
      storage = storages.first
      storage.volumes.new attr
    rescue => e
      logger.warn "failed to initialize volume: #{e}"
      raise e
    end

    def new_volume_errors
      []
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
      super.merge(vmid: next_vmid, node: node)
    end

    private

    def node
      get_cluster_node
    end

    def get_cluster_node(args = {})
      args.empty? ? client.nodes.first : client.nodes.find_by_id(args[:node])
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
