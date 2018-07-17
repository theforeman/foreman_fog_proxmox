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

require 'fog/proxmox'

module ForemanFogProxmox
  class Proxmox < ComputeResource
    include ProxmoxComputeHelper
    validates :url, :format => { :with => URI::DEFAULT_PARSER.make_regexp }, :presence => true
    validates :user, :format => { :with => /(\w+)[@]{1}(\w+)/ }, :presence => true
    validates :password, :presence => true
    before_create :test_connection
    attr_accessor :node

    def provided_attributes
      super.merge(
        :mac  => :mac
      )
    end
    
    def self.provider_friendly_name
      "Proxmox"
    end

    def capabilities
      [:build, :new_volume, :image]
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

    def storages_isos
      storages = node.storages.list_by_content_type 'iso'
      storages.sort_by(&:storage)
    end

    def isos(storage_id)
      storage = node.storages.find_by_id storage_id if storage_id
      storage.volumes.list_by_content_type('iso').sort_by(&:volid) if storage
    end

    def associated_host(vm)
      associate_by('mac', vm.mac)
    end

    def bridges
      node = network_client.nodes.all.first
      bridges = node.networks.all(type: 'bridge')
      bridges.sort_by(&:iface)
    end    

    def available_images
      templates.collect { |template| OpenStruct.new(id: template.vmid) }
    end

    def templates
      storage = storages.first
      images = storage.volumes.list_by_content_type('images')
      images.select { |image| image.templated? }
    end

    def template(vmid)
      find_vm_by_uuid(vmid)
    end

    def host_compute_attrs(host)
      super.tap do |attrs|
        ostype = host.compute_attributes['config_attributes']['ostype']
        raise Foreman::Exception.new(N_("Operating system family %{type} is not consistent with %{ostype}", { type: host.operatingsystem.type, ostype: ostype })) unless compute_os_types(host).include?(ostype)
      end
    end

    def host_interfaces_attrs(host)
      host.interfaces.select(&:physical?).each.with_index.reduce({}) do |hash, (nic, index)|
        raise ::Foreman::Exception.new N_("Identifier interface[%{index}] required.", { index: index }) if nic.identifier.empty?
        raise ::Foreman::Exception.new N_("Invalid identifier interface[%{index}]. Must be net[n] with n integer >= 0", { index: index }) unless Fog::Proxmox::ControllerHelper.valid?(Fog::Compute::Proxmox::Interface::NAME,nic.identifier)
        hash.merge(index.to_s => nic.compute_attributes.merge(id: nic.identifier, ip: nic.ip, ip6: nic.ip6))
      end
    end

    def new_volume(attr = {})     
      opts = volume_defaults('scsi',1).merge(attr.to_h).deep_symbolize_keys
      opts[:size] = opts[:size].to_s
      Fog::Compute::Proxmox::Disk.new(opts)
    end

    def new_interface(attr = {})
      opts = interface_defaults.merge(attr.to_h).deep_symbolize_keys
      Fog::Compute::Proxmox::Interface.new(opts)
    end

    def vm_compute_attributes(vm)
      vm_attrs = vm.attributes rescue {}
      vm_attrs = vm_attrs.reject{|k,v| k == :id }  
      vm_attrs = set_vm_volumes_attributes(vm, vm_attrs)
      vm_attrs = set_vm_interfaces_attributes(vm, vm_attrs)
      vm_attrs
    end

    def set_vm_volumes_attributes(vm, vm_attrs)
      if vm.config.respond_to?(:volumes)
        volumes = vm.config.volumes || []
        vm_attrs[:volumes_attributes] = Hash[volumes.each_with_index.map { |volume, idx| [idx.to_s, volume.attributes] }]
      end
      vm_attrs
    end

    def set_vm_interfaces_attributes(vm, vm_attrs)
      if vm.config.respond_to?(:interfaces)
        interfaces = vm.config.interfaces || []
        vm_attrs[:interfaces_attributes] = Hash[interfaces.each_with_index.map { |interface, idx| [idx.to_s, interface.attributes] }]
      end
      vm_attrs
    end

    def new_vm(attr = {})
      vm = node.servers.new(vm_instance_defaults.merge(parse_vm(attr)))
      logger.debug(N_("new_vm() vm.config=%{config}", { config: vm.config.inspect } ))
      vm
    end

    def create_vm(args = {})
      vmid = args[:vmid]
      raise ::Foreman::Exception.new N_("invalid vmid=%{vmid}", { vmid: vmid }) unless node.servers.id_valid?(vmid)
      image_id = args[:image_id]
      node = get_cluster_node args
      if image_id
        logger.debug(N_("create_vm(): clone %{image_id} in %{vmid}", { image_id: image_id, vmid: vmid }))
        image = node.servers.get image_id
        image.clone(vmid)
      else
        logger.debug(N_("create_vm(): %{args}", { args: args }))
        convert_sizes(args)
        node.servers.create(parse_vm(args))
      end
      vm = find_vm_by_uuid(vmid)
      vm
    rescue => e
      logger.warn N_("failed to create vm: %{e}", { e: e })
      destroy_vm vm.id if vm
      raise e
    end

    def find_vm_by_uuid(uuid)
      node.servers.get(uuid)
    rescue Fog::Errors::Error => e
      Foreman::Logging.exception(N_("Failed retrieving proxmox vm by vmid=%{uuid}", { uuid: uuid }), e)
      raise(ActiveRecord::RecordNotFound)
    end

    def supports_update?
      true
    end

    def update_required?(old_attrs, new_attrs)
      return true if super(old_attrs, new_attrs)

      new_attrs[:interfaces_attributes].each do |key, interface|
        return true if (interface[:id].blank? || interface[:_delete] == '1') && key != 'new_interfaces' #ignore the template
      end if new_attrs[:interfaces_attributes]

      new_attrs[:volumes_attributes].each do |key, volume|
        return true if (volume[:id].blank? || volume[:_delete] == '1') && key != 'new_volumes' #ignore the template
      end if new_attrs[:volumes_attributes]

      false
    end

    def editable_network_interfaces?
      true
    end

    def user_data_supported?
      true
    end

    def image_exists?(image)
      find_vm_by_uuid(image)
    end

    def save_vm(uuid, attr)
      vm = find_vm_by_uuid(uuid)
      logger.debug(N_("save_vm(): %{attr}", { attr: attr }))
      templated = attr[:templated]
      if (templated == '1' && !vm.templated?)
        vm.template
      else
        merged = vm.config.attributes.merge!(parse_vm(attr).symbolize_keys).deep_symbolize_keys
        filtered = merged.reject { |key,value| %w[node vmid].include?(key) || [:templated,:image_id].include?(key) || value.to_s.empty? }
        vm.update(filtered)
      end
    end

    def next_vmid
      node.servers.next_id
    end

    def node
      @node ||= get_cluster_node
    end

    def ssl_certs  
      self.attrs[:ssl_certs]
    end

    def ssl_certs=(value)
      self.attrs[:ssl_certs] = value
    end

    def certs_to_store
      return if ssl_certs.blank?
      store = OpenSSL::X509::Store.new
      ssl_certs.split(/(?=-----BEGIN)/).each do |cert|
        x509_cert = OpenSSL::X509::Certificate.new cert
        store.add_cert x509_cert
      end
      store
    rescue => e
      logger.error(e)
      raise ::Foreman::Exception.new N_("Unable to store X509 certificates")
    end

    def ssl_verify_peer
      self.attrs[:ssl_verify_peer].blank? ? false : Foreman::Cast.to_bool(self.attrs[:ssl_verify_peer])
    end

    def ssl_verify_peer=(value)
      self.attrs[:ssl_verify_peer] = value
    end

    def connection_options
      opts = http_proxy ? {proxy: http_proxy.full_url} : {disable_proxy: 1}
      opts.store(:ssl_verify_peer, ssl_verify_peer)
      opts.store(:ssl_cert_store, certs_to_store) if Foreman::Cast.to_bool(ssl_verify_peer)
      opts
    end

    def console(uuid)
      vm = find_vm_by_uuid(uuid)
      if vm.config.type_console == 'vnc'
        vnc_console = vm.start_console(websocket: 1)  
        WsProxy.start(:host => host, :host_port => vnc_console['port'], :password => vnc_console['ticket']).merge(:name => vm.name, :type => vm.config.type_console)
      else
        raise ::Foreman::Exception.new(N_("%s console is not supported at this time", vm.config.type_console))
      end
    end

    private

    def fog_credentials
     { pve_url: url,
        pve_username: user,
        pve_password: password,
        connection_options: connection_options }
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
        node: node.to_s, 
        cores: 1, 
        sockets: 1, 
        kvm: 0,
        vga: 'std',
        memory: 512 * MEGA, 
        ostype: 'l26',
        keyboard: 'en-us',
        cpu: 'kvm64',
        scsihw: 'virtio-scsi-pci',
        ide2: "none,media=cdrom",
        templated: 0
      ).merge(Fog::Proxmox::DiskHelper.flatten(volume_defaults)).merge(Fog::Proxmox::NicHelper.flatten(interface_defaults))
    end

    def volume_defaults(controller = 'scsi', device = 0)
      id = "#{controller}#{device}"
      { id: id, storage: storages.first.to_s, size: (8 * GIGA), options: { cache: 'none' } }
    end

    def interface_defaults(id = 'net0')
      { id: id, model: 'virtio', bridge: bridges.first.to_s }
    end

    def get_cluster_node(args = {})
      test_connection
      args.empty? ? client.nodes.first : client.nodes.find_by_id(args[:node])  if errors.empty?
    end 
    
    def compute_os_types(host)
      os_linux_types_mapping(host).empty? ? os_windows_types_mapping(host) : os_linux_types_mapping(host)
    end

    def available_operating_systems
      operating_systems = %w[other solaris]
      operating_systems += available_linux_operating_systems
      operating_systems += available_windows_operating_systems
      operating_systems
    end

    def available_linux_operating_systems
      %w[l24 l26]
    end

    def available_windows_operating_systems
      %w[wxp w2k w2k3 w2k8 wvista win7 win8 win10]
    end

    def os_linux_types_mapping(host)
      %w[Debian Redhat Suse Altlinux Archlinux CoreOs Gentoo].include?(host.operatingsystem.type) ? available_linux_operating_systems : []
    end

    def os_windows_types_mapping(host)
      %w[Windows].include?(host.operatingsystem.type) ? available_windows_operating_systems : []
    end

    def convert_sizes(args)
      args['config_attributes']['memory'] = (args['config_attributes']['memory'].to_i / MEGA).to_s
      args['config_attributes']['min_memory'] = (args['config_attributes']['min_memory'].to_i / MEGA).to_s
      args['config_attributes']['shares'] = (args['config_attributes']['shares'].to_i / MEGA).to_s
      args['volumes_attributes'].each_value { |value| value['size'] = (value['size'].to_i / GIGA).to_s }
    end

    def host
      URI.parse(url).host
    end

  end
end
