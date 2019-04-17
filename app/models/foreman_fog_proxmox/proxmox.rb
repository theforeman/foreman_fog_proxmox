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
require 'foreman_fog_proxmox/semver'

module ForemanFogProxmox
  class Proxmox < ComputeResource
    include ProxmoxVmHelper
    include ProxmoxServerHelper
    include ProxmoxContainerHelper
    validates :url, :format => { :with => URI::DEFAULT_PARSER.make_regexp }, :presence => true
    validates :user, :format => { :with => /(\w+)[@]{1}(\w+)/ }, :presence => true
    validates :password, :presence => true
    validates :node_id, :presence => true
    before_create :test_connection

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
      errors[:url].empty? && errors[:user].empty? && errors[:user].include?('@') && errors[:password].empty? && errors[:node_id].empty?
    end

    def version_suitable?
      logger.debug(_("Proxmox compute resource version is %{version}") % { version: version })
      raise ::Foreman::Exception.new(_("Proxmox version %{version} is not semver suitable") % { version: version }) unless ForemanFogProxmox::Semver.is_semver?(version)
      ForemanFogProxmox::Semver.to_semver(version) >= ForemanFogProxmox::Semver.to_semver("5.3.0") && ForemanFogProxmox::Semver.to_semver(version) < ForemanFogProxmox::Semver.to_semver("5.5.0")
    end

    def test_connection(options = {})
      super
      credentials_valid?
      version_suitable?
    rescue => e
      errors[:base] << e.message
      errors[:url] << e.message
    end

    def nodes
      nodes = client.nodes.all if client
      nodes.sort_by(&:node) if nodes
    end

    def pools
      pools = identity_client.pools.all
      pools.sort_by(&:poolid)
    end

    def storages(type = 'images')
      storages = node.storages.list_by_content_type type
      storages.sort_by(&:storage)
    end

    def images_by_storage(type = 'iso', storage_id)
      storage = node.storages.get storage_id if storage_id
      storage.volumes.list_by_content_type(type).sort_by(&:volid) if storage
    end

    def associated_host(vm)
      associate_by('mac', vm.mac)
    end

    def bridges
      node = network_client.nodes.get node_id
      bridges = node.networks.all(type: 'any_bridge')
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
        type = host.compute_attributes['type']
        case type
        when 'lxc'
          host.compute_attributes['config_attributes'].store('hostname',host.name)
        when 'qemu'
          raise ::Foreman::Exception.new(_("Operating system family %{type} is not consistent with %{ostype}") % { type: host.operatingsystem.type, ostype: ostype }) unless compute_os_types(host).include?(ostype)
        end
      end
    end

    def host_interfaces_attrs(host)
      host.interfaces.select(&:physical?).each.with_index.reduce({}) do |hash, (nic, index)|
        # Set default interface identifier to net[n]
        nic.identifier = "net%{index}" % {index: index} if nic.identifier.empty?
        raise ::Foreman::Exception.new _("Invalid identifier interface[%{index}]. Must be net[n] with n integer >= 0" % { index: index }) unless Fog::Proxmox::NicHelper.valid?(nic.identifier)
        # Set default container interface name to eth[n]
        container = host.compute_attributes['type'] == 'lxc'
        nic.compute_attributes['name'] = "eth%{index}" % {index: index} if container && nic.compute_attributes['name'].empty?
        raise ::Foreman::Exception.new _("Invalid name interface[%{index}]. Must be eth[n] with n integer >= 0" % { index: index }) if container && !/^(eth)(\d+)$/.match?(nic.compute_attributes['name'])
        nic_compute_attributes = nic.compute_attributes.merge(id: nic.identifier)
        nic_compute_attributes.store(:ip, nic.ip) if (nic.ip && !nic.ip.empty?)
        nic_compute_attributes.store(:ip6, nic.ip6) if (nic.ip6 && !nic.ip6.empty?)
        hash.merge(index.to_s => nic_compute_attributes)
      end
    end

    def new_volume(attr = {})     
      type = attr['type']
      type = 'qemu' unless type
      case type
      when 'lxc'
        return new_volume_server(attr)
      when 'qemu'
        return new_volume_container(attr)
      end
    end

    def new_volume_server(attr = {})
      opts = volume_server_defaults.merge(attr.to_h).deep_symbolize_keys
      opts[:size] = opts[:size].to_s
      Fog::Compute::Proxmox::Disk.new(opts)
    end

    def new_volume_container(attr = {})
      id = attr[:id]
      opts = volume_container_defaults(id).merge(attr.to_h).deep_symbolize_keys
      opts[:size] = opts[:size].to_s
      Fog::Compute::Proxmox::Disk.new(opts)
    end

    def new_interface(attr = {}) 
      type = attr['type']
      type = 'qemu' unless type
      case type
      when 'lxc'
        return new_container_interface(attr)
      when 'qemu'
        return new_server_interface(attr)
      end
    end

    def new_server_interface(attr = {})
      logger.debug("new_server_interface")
      opts = interface_server_defaults.merge(attr.to_h).deep_symbolize_keys
      Fog::Compute::Proxmox::Interface.new(opts)
    end

    def new_container_interface(attr = {})
      logger.debug("new_container_interface")
      opts = interface_container_defaults.merge(attr.to_h).deep_symbolize_keys
      Fog::Compute::Proxmox::Interface.new(opts)
    end

    # used by host.clone
    def vm_compute_attributes(vm)
      vm_attrs = vm.attributes.reject { |key,value| [:config, :vmid].include?(key.to_sym) || value.to_s.empty? }
      vm_attrs = set_vm_config_attributes(vm, vm_attrs)
      vm_attrs = set_vm_volumes_attributes(vm, vm_attrs)
      vm_attrs = set_vm_interfaces_attributes(vm, vm_attrs)
      vm_attrs
    end

    def set_vm_config_attributes(vm, vm_attrs)
      if vm.respond_to?(:config)
        config = vm.config.attributes.reject { |key,value| [:disks, :interfaces, :vmid].include?(key) || value.to_s.empty?}
        vm_attrs[:config_attributes] = config
      end
      vm_attrs
    end

    def set_vm_volumes_attributes(vm, vm_attrs)
      if vm.config.respond_to?(:disks)
        volumes = vm.config.disks || []
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

    def vms(opts = {})
      node
    end

    def new_vm(new_attr = {})
      new_attr = ActiveSupport::HashWithIndifferentAccess.new(new_attr)
      type = new_attr['type']
      type = 'qemu' unless type
      case type
      when 'lxc'
        vm = new_container_vm(new_attr)
      when 'qemu'
        vm = new_server_vm(new_attr)
      end
      logger.debug(_("new_vm() vm.config=%{config}") % { config: vm.config.inspect })
      vm
    end

    def new_container_vm(new_attr = {})
      new_attr.merge(node_id: node_id)
      vm = node.containers.new(parse_container_vm(vm_container_instance_defaults.merge(new_attr.merge(type: 'lxc'))).deep_symbolize_keys)
      logger.debug(_("new_container_vm() vm.config=%{config}") % { config: vm.config.inspect })
      vm
    end

    def new_server_vm(new_attr = {})
      new_attr.merge(node_id: node_id)
      vm = node.servers.new(parse_server_vm(vm_server_instance_defaults.merge(new_attr.merge(type: 'qemu'))).deep_symbolize_keys)
      logger.debug(_("new_server_vm() vm.config=%{config}") % { config: vm.config.inspect })
      vm
    end

    def create_vm(args = {})
      vmid = args[:vmid].to_i
      type = args[:type]
      raise ::Foreman::Exception.new N_("invalid vmid=%{vmid}") % { vmid: vmid } unless node.servers.id_valid?(vmid)
      image_id = args[:image_id]
      if image_id
        logger.debug(_("create_vm(): clone %{image_id} in %{vmid}") % { image_id: image_id, vmid: vmid })
        image = node.servers.get image_id
        image.clone(vmid)
        clone = node.servers.get vmid
        clone.update(name: args[:name])        
      else
        convert_sizes(args)
        remove_deletes(args)
        case type
          when 'qemu'
            vm = node.servers.create(parse_server_vm(args))
          when 'lxc'
            hash = parse_container_vm(args)
            hash = hash.merge(vmid: vmid)
            vm = node.containers.create(hash.reject { |key,_value| %w[ostemplate_storage ostemplate_file].include? key })
        end
      end
    rescue => e
      logger.warn(_("failed to create vm: %{e}") % { e: e })
      destroy_vm vm.id if vm
      raise e
    end

    def find_vm_by_uuid(uuid)
      begin
        vm = node.servers.get(uuid)
      rescue Fog::Errors::NotFound
        vm = nil  
      rescue Fog::Errors::Error => e
        Foreman::Logging.exception(_("Failed retrieving proxmox server vm by vmid=%{uuid}") % { vmid: uuid }, e)
        raise(ActiveRecord::RecordNotFound)
      end
      begin
        vm = node.containers.get(uuid) unless vm
      rescue Fog::Errors::NotFound
        vm = nil  
      rescue Fog::Errors::Error => e
        Foreman::Logging.exception(_("Failed retrieving proxmox container vm by vmid=%{uuid}") % { vmid: uuid }, e)
        raise(ActiveRecord::RecordNotFound)
      end
      vm
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
      !find_vm_by_uuid(image).nil?
    end

    def save_vm(uuid, new_attributes)
      vm = find_vm_by_uuid(uuid)
      templated = new_attributes[:templated]
      if (templated == '1' && !vm.templated?)
        vm.create_template
      else
        parsed_attr = vm.container? ? parse_container_vm(new_attributes.merge(type: vm.type)) : parse_server_vm(new_attributes.merge(type: vm.type))
        vm.update(parsed_attr.reject { |key,value| [:templated,:ostemplate,:ostemplate_file,:ostemplate_storage].include? key.to_sym || ForemanFogProxmox::Value.empty?(value) })
      end
      vm = find_vm_by_uuid(uuid)
    end

    def next_vmid
      node.servers.next_id
    end

    def node_id  
      self.attrs[:node_id]
    end

    def node_id=(value)
      self.attrs[:node_id] = value
    end

    def node
      client.nodes.get node_id
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
      options = {}
      if vm.container?
        type_console = 'vnc'
        options.store(:console, type_console)
      else
        type_console = vm.config.type_console
      end
        options.store(:websocket, 1) if type_console == 'vnc'
      begin
        vnc_console = vm.start_console(options)  
        WsProxy.start(:host => host, :host_port => vnc_console['port'], :password => vnc_console['ticket']).merge(:name => vm.name, :type => type_console)
      rescue => e
        logger.error(e)
        raise ::Foreman::Exception.new(_("%s console is not supported at this time") % type_console)
      end
    end

    def version
      v = identity_client.read_version
      "#{v['version']}.#{v['release']}"
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

    def vm_server_instance_defaults
      ActiveSupport::HashWithIndifferentAccess.new(
        name: "foreman_#{Time.now.to_i}",
        vmid: next_vmid, 
        type: 'qemu', 
        node_id: node_id, 
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
        templated: 0).merge(Fog::Proxmox::DiskHelper.flatten(volume_server_defaults)).merge(Fog::Proxmox::DiskHelper.flatten(volume_container_defaults)).merge(Fog::Proxmox::NicHelper.flatten(interface_defaults))
    end

    def vm_container_instance_defaults
      ActiveSupport::HashWithIndifferentAccess.new(
        name: "foreman_#{Time.now.to_i}",
        vmid: next_vmid, 
        type: 'lxc', 
        node_id: node_id, 
        memory: 512 * MEGA, 
        templated: 0).merge(Fog::Proxmox::DiskHelper.flatten(volume_container_defaults)).merge(Fog::Proxmox::DiskHelper.flatten(volume_server_defaults)).merge(Fog::Proxmox::NicHelper.flatten(interface_defaults))
    end

    def vm_instance_defaults
      super.merge(vmid: next_vmid, node_id: node_id)
    end

    def volume_server_defaults(controller = 'scsi', device = 0)
      id = "#{controller}#{device}"
      { id: id, storage: storages.first.identity.to_s, size: (8 * GIGA), options: { cache: 'none' } }
    end

    def volume_container_defaults(id='rootfs')
      { id: id, storage: storages.first.identity.to_s, size: (8 * GIGA), options: {  } }
    end

    def interface_defaults(id = 'net0')
      { id: id, model: 'virtio', name: 'eth0', bridge: bridges.first.identity.to_s }
    end

    def interface_server_defaults(id = 'net0')
      { id: id, model: 'virtio', bridge: bridges.first.identity.to_s }
    end

    def interface_container_defaults(id = 'net0')
      { id: id, name: 'eth0', bridge: bridges.first.identity.to_s }
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
      %w[l24 l26 debian ubuntu centos fedora opensuse archlinux gentoo alpine]
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

    def host
      URI.parse(url).host
    end

  end
end
