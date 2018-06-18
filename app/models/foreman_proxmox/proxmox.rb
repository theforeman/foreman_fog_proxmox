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
    include ProxmoxComputeHelper
    validates :url, :format => { :with => URI::DEFAULT_PARSER.make_regexp }, :presence => true
    validates :user, :format => { :with => /(\w+)[@]{1}(\w+)/ }, :presence => true
    validates :password, :presence => true
    before_create :test_connection
    attr_accessor :ssl_verify_peer, :disable_proxy, :node

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

    def self.model_name
      ComputeResource.model_name
    end

    def credentials_valid?
      errors[:url].empty? && errors[:user].empty? && errors[:user].include?('@') && errors[:password].empty? && node
    end

    def test_connection(options = {})
      super
      credentials_valid?
    rescue => e
      errors[:base] << e.message
      errors[:url] << e.message
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
      storages = node.storages.list_by_content_type 'images'
      storages.sort_by(&:storage)
    end

    def associated_host(vm)
      associate_by('node', vm.node)
    end

    def interfaces
      node.server.config.interfaces.all
    rescue
      []
    end

    def bridges
      node = network_client.nodes.all.first
      bridges = node.networks.all(type: 'bridge')
      bridges.sort_by(&:iface)
    end

    def templates
      node.server.disk_images.all
    rescue
      []
    end

    def new_interface(attr = {})
      Fog::Compute::Proxmox::Interface.new interface_defaults.merge(attr.to_hash.deep_symbolize_keys)
    end

    def host_interfaces_attrs(host)
      host.interfaces.select(&:physical?).each.with_index.reduce({}) do |hash, (nic, index)|
        raise ::Foreman::Exception.new N_("Identifier interface[#{index}] required.") if nic.identifier.empty?
        raise ::Foreman::Exception.new N_("Invalid identifier interface[#{index}]. Must be net[n] with n integer >= 0") unless Fog::Proxmox::ControllerHelper.valid?(Fog::Compute::Proxmox::Interface::NAME,nic.identifier)
        hash.merge(index.to_s => nic.compute_attributes.merge(id: nic.identifier, ip: nic.ip, ip6: nic.ip6))
      end
    end

    def new_vm(attr = {})
      vm = node.servers.new(vm_instance_defaults.merge(attr.to_hash.deep_symbolize_keys)) if errors.empty?
      logger.debug("new_vm() vm.config=#{vm.config.inspect}")
      vm
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

    def find_vm_by_uuid(uuid)
      node.servers.get(uuid)
    rescue Fog::Errors::Error => e
      Foreman::Logging.exception("Failed retrieving proxmox vm by vmid #{uuid}", e)
      raise(ActiveRecord::RecordNotFound) if e.message.include?('HANDLE_INVALID')
      raise(ActiveRecord::RecordNotFound) if e.message.include?('VM.get_record: ["SESSION_INVALID"')
      raise e
    end

    def next_vmid
      node.servers.next_id
    end

    def new_volume(attr = {})
      Fog::Compute::Proxmox::Disk.new volume_defaults.merge(attr.to_hash.deep_symbolize_keys)
    rescue => e
      logger.warn "failed to initialize volume: #{e}"
      raise e
    end

    def new_volume_errors
      errors = []
      errors.push _('no storage available on hypervisor') if storages.empty?
      errors
    end

    def node
      @node ||= get_cluster_node
    end

    private

    def fog_credentials
      disable_proxy = disable_proxy ? Foreman::Cast.to_bool(disable_proxy) : true # dev tests only
      ssl_verify_peer = ssl_verify_peer ? Foreman::Cast.to_bool(ssl_verify_peer) : false # dev tests only
      { pve_url: url,
        pve_username: user,
        pve_password: password,
        connection_options: { disable_proxy: disable_proxy, ssl_verify_peer: ssl_verify_peer } } 
    end

    def client
      @client ||= ::Fog::Compute::Proxmox.new(fog_credentials)
    end

    def identity_client
      @identity_client ||= ::Fog::Identity::Proxmox.new(fog_credentials)
    end

    def network_client
      @network_client ||= ::Fog::Network::Proxmox.new(fog_credentials)
    end

    def disconnect
      client.terminate if @client
      @client = nil
      identity_client.terminate if @identity_client
      @identity_client = nil
      network_client.terminate if @network_client
      @network_client = nil
    end

    def vm_instance_defaults
      super.merge(
        vmid: next_vmid, 
        type: 'qemu', 
        node: node, 
        cores: 1, 
        sockets: 1, 
        memory: 512 * 1024 * 1024, 
        ostype: 'l26',
        cpu: 'kvm64',
        scsihw: 'virtio-scsi-pci',
        scsi0: "#{storages.first}:8",
        net0: "virtio,bridge=#{bridges.first}"
      )
    end

    def volume_defaults
      { id: 'scsi0', storage: storages.first, size: 8 }
    end

    def interface_defaults
      { id: 'net0', model: 'virtio', bridge: bridges.first }
    end

    def get_cluster_node(args = {})
      args.empty? ? client.nodes.first : client.nodes.find_by_id(args[:node])
    end

  end
end
