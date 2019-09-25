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
require 'fog/proxmox/helpers/nic_helper'
require 'fog/proxmox/helpers/disk_helper'
require 'foreman_fog_proxmox/semver'
require 'foreman_fog_proxmox/value'

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
        :mac => :mac
      )
    end

    def self.provider_friendly_name
      'Proxmox'
    end

    def capabilities
      [:build, :new_volume, :new_interface, :image]
    end

    def self.model_name
      ComputeResource.model_name
    end

    def credentials_valid?
      errors[:url].empty? && errors[:user].empty? && errors[:user].include?('@') && errors[:password].empty? && errors[:node_id].empty?
    end

    def version_suitable?
      logger.debug(format(_('Proxmox compute resource version is %<version>s'), version: version))
      raise ::Foreman::Exception, format(_('Proxmox version %<version>s is not semver suitable'), version: version) unless ForemanFogProxmox::Semver.is_semver?(version)

      ForemanFogProxmox::Semver.to_semver(version) >= ForemanFogProxmox::Semver.to_semver('5.3.0') && ForemanFogProxmox::Semver.to_semver(version) < ForemanFogProxmox::Semver.to_semver('5.5.0')
    end

    def test_connection(options = {})
      super
      credentials_valid?
      version_suitable?
    rescue StandardError => e
      errors[:base] << e.message
      if e.message.include?('SSL')
        errors[:ssl_certs] << e.message
      else
        errors[:url] << e.message
      end
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
      images.select(&:templated?)
    end

    def template(vmid)
      find_vm_by_uuid(vmid)
    end

    def host_compute_attrs(host)
      super.tap do |_attrs|
        ostype = host.compute_attributes['config_attributes']['ostype']
        type = host.compute_attributes['type']
        case type
        when 'lxc'
          host.compute_attributes['config_attributes'].store('hostname', host.name)
        when 'qemu'
          raise ::Foreman::Exception, format(_('Operating system family %<type>s is not consistent with %<ostype>s'), type: host.operatingsystem.type, ostype: ostype) unless compute_os_types(host).include?(ostype)
        end
      end
    end

    def host_interfaces_attrs(host)
      host.interfaces.select(&:physical?).each.with_index.reduce({}) do |hash, (nic, index)|
        # Set default interface identifier to net[n]
        nic.identifier = format('net%{index}', index: index) if nic.identifier.empty?
        raise ::Foreman::Exception, _(format('Invalid identifier interface[%{index}]. Must be net[n] with n integer >= 0', index: index)) unless Fog::Proxmox::NicHelper.nic?(nic.identifier)

        # Set default container interface name to eth[n]
        container = host.compute_attributes['type'] == 'lxc'
        nic.compute_attributes['name'] = format('eth%{index}', index: index) if container && nic.compute_attributes['name'].empty?
        raise ::Foreman::Exception, _(format('Invalid name interface[%{index}]. Must be eth[n] with n integer >= 0', index: index)) if container && !/^(eth)(\d+)$/.match?(nic.compute_attributes['name'])

        nic_compute_attributes = nic.compute_attributes.merge(id: nic.identifier)
        mac = nic.mac
        mac ||= nic.attributes['mac']
        nic_compute_attributes.store(:macaddr, mac) if mac.present?
        interface_compute_attributes = host.compute_attributes['interfaces_attributes'].select { |_k, v| v['id'] == nic.identifier }
        nic_compute_attributes.store(:_delete, interface_compute_attributes[interface_compute_attributes.keys[0]]['_delete']) unless interface_compute_attributes.empty?
        nic_compute_attributes.store(:ip, nic.ip) if nic.ip.present?
        nic_compute_attributes.store(:ip6, nic.ip6) if nic.ip6.present?
        hash.merge(index.to_s => nic_compute_attributes)
      end
    end

    def new_volume(attr = {})
      type = attr['type']
      type ||= 'qemu'
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
      Fog::Proxmox::Compute::Disk.new(opts)
    end

    def new_volume_container(attr = {})
      opts = volume_container_defaults.merge(attr.to_h).deep_symbolize_keys
      opts[:size] = opts[:size].to_s
      Fog::Proxmox::Compute::Disk.new(opts)
    end

    def new_interface(attr = {})
      type = attr['type']
      type ||= 'qemu'
      case type
      when 'lxc'
        return new_container_interface(attr)
      when 'qemu'
        return new_server_interface(attr)
      end
    end

    def new_server_interface(attr = {})
      logger.debug('new_server_interface')
      opts = interface_server_defaults.merge(attr.to_h).deep_symbolize_keys
      Fog::Proxmox::Compute::Interface.new(opts)
    end

    def new_container_interface(attr = {})
      logger.debug('new_container_interface')
      opts = interface_container_defaults.merge(attr.to_h).deep_symbolize_keys
      Fog::Proxmox::Compute::Interface.new(opts)
    end

    def vm_compute_attributes(vm)
      vm_attrs = {}
      if vm.respond_to?(:config)
        vm_attrs = vm_attrs.merge(vmid: vm.identity, node_id: vm.node_id, type: vm.type)
        if vm.config.respond_to?(:disks)
          vm_attrs[:volumes_attributes] = Hash[vm.config.disks.each_with_index.map { |disk, idx| [idx.to_s, disk.attributes] }]
        end
        if vm.config.respond_to?(:interfaces)
          vm_attrs[:interfaces_attributes] = Hash[vm.config.interfaces.each_with_index.map { |interface, idx| [idx.to_s, interface.attributes] }]
        end
        vm_attrs[:config_attributes] = vm.config.attributes.reject { |key, value| [:disks, :interfaces, :vmid, :node_id, :node, :type].include?(key) || !vm.config.respond_to?(key) || ForemanFogProxmox::Value.empty?(value.to_s) || Fog::Proxmox::DiskHelper.disk?(key.to_s) || Fog::Proxmox::NicHelper.nic?(key.to_s) }
      end
      vm_attrs
    end

    def vms(_opts = {})
      node
    end

    def new_vm(new_attr = {})
      new_attr = ActiveSupport::HashWithIndifferentAccess.new(new_attr)
      type = new_attr['type']
      type ||= 'qemu'
      case type
      when 'lxc'
        vm = new_container_vm(new_attr)
      when 'qemu'
        vm = new_server_vm(new_attr)
      end
      logger.debug(format(_('new_vm() vm.config=%{config}'), config: vm.config.inspect))
      vm
    end

    def new_container_vm(new_attr = {})
      options = new_attr
      options = options.merge(node_id: node_id).merge(type: 'lxc').merge(vmid: next_vmid)
      options = vm_container_instance_defaults.merge(options) if new_attr.empty?
      vm = node.containers.new(parse_container_vm(options).deep_symbolize_keys)
      logger.debug(format(_('new_container_vm() vm.config=%{config}'), config: vm.config.inspect))
      vm
    end

    def new_server_vm(new_attr = {})
      options = new_attr
      options = options.merge(node_id: node_id).merge(type: 'qemu').merge(vmid: next_vmid)
      options = vm_server_instance_defaults.merge(options) if new_attr.empty?
      vm = node.servers.new(parse_server_vm(options).deep_symbolize_keys)
      logger.debug(format(_('new_server_vm() vm.config=%{config}'), config: vm.config.inspect))
      vm
    end

    def create_vm(args = {})
      vmid = args[:vmid].to_i
      type = args[:type]
      raise ::Foreman::Exception, format(N_('invalid vmid=%{vmid}'), vmid: vmid) unless node.servers.id_valid?(vmid)

      image_id = args[:image_id]
      if image_id
        logger.debug(format(_('create_vm(): clone %{image_id} in %{vmid}'), image_id: image_id, vmid: vmid))
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
          vm = node.containers.create(hash.reject { |key, _value| ['ostemplate_storage', 'ostemplate_file'].include? key })
        end
      end
    rescue StandardError => e
      logger.warn(format(_('failed to create vm: %{e}'), e: e))
      destroy_vm vm.id if vm
      raise e
    end

    def destroy_vm(uuid)
      vm = find_vm_by_uuid(uuid)
      vm.stop
      vm.destroy
    rescue ActiveRecord::RecordNotFound
      # if the VM does not exists, we don't really care.
      true
    end

    def find_vm_by_uuid(uuid)
      # look for the uuid on all known nodes
      vm = nil
      nodes.each do |node|
        vm = save_find_vm_in_servers_by_uuid(node.servers, uuid)
        vm ||= save_find_vm_in_servers_by_uuid(node.containers, uuid)
        unless vm.nil?
          logger.debug("found vm #{uuid} on node #{node.node}")
          break
        end
      end
      vm
    end

    def supports_update?
      true
    end

    def update_required?(old_attrs, new_attrs)
      return true if super(old_attrs, new_attrs)

      new_attrs[:interfaces_attributes]&.each do |key, interface|
        return true if (interface[:id].blank? || interface[:_delete] == '1') && key != 'new_interfaces' # ignore the template
      end

      new_attrs[:volumes_attributes]&.each do |key, volume|
        return true if (volume[:id].blank? || volume[:_delete] == '1') && key != 'new_volumes' # ignore the template
      end

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

    def save_volumes(vm, volumes_attributes)
      volumes_attributes&.each_value do |volume_attributes|
        id = volume_attributes['id']
        disk = vm.config.disks.get(id)
        delete = volume_attributes['_delete']
        if disk && volume_attributes['volid'].present?
          if delete == '1'
            vm.detach(id)
            device = Fog::Proxmox::DiskHelper.extract_device(id)
            vm.detach('unused' + device.to_s)
          else
            diff_size = volume_attributes['size'].to_i - disk.size
            raise ::Foreman::Exception, format(_('Unable to shrink %<id>s size. Proxmox allows only increasing size.'), id: id) unless diff_size >= 0

            if diff_size > 0
              extension = '+' + (diff_size / GIGA).to_s + 'G'
              vm.extend(id, extension)
            elsif disk.storage != volume_attributes['storage']
              vm.move(id, volume_attributes['storage'])
            end
          end
        else
          options = {}
          options.store(:mp, volume_attributes['mp']) if vm.container?
          disk_attributes = { id: id, storage: volume_attributes['storage'], size: (volume_attributes['size'].to_i / GIGA).to_s }
          vm.attach(disk_attributes, options) unless delete == '1'
        end
      end
    end

    def save_vm(uuid, new_attributes)
      vm = find_vm_by_uuid(uuid)
      templated = new_attributes['templated']
      if templated == '1' && !vm.templated?
        vm.create_template
      else
        volumes_attributes = new_attributes['volumes_attributes']
        save_volumes(vm, volumes_attributes)
        parsed_attr = vm.container? ? parse_container_vm(new_attributes.merge(type: vm.type)) : parse_server_vm(new_attributes.merge(type: vm.type))
        config_attributes = parsed_attr.reject { |key, _value| [:templated, :ostemplate, :ostemplate_file, :ostemplate_storage, :volumes_attributes].include? key.to_sym }
        config_attributes = config_attributes.reject { |_key, value| ForemanFogProxmox::Value.empty?(value) }
        cdrom_attributes = parsed_attr.select { |_key, value| Fog::Proxmox::DiskHelper.cdrom?(value.to_s) }
        config_attributes = config_attributes.reject { |key, _value| Fog::Proxmox::DiskHelper.disk?(key) }
        vm.update(config_attributes.merge(cdrom_attributes))
      end
      find_vm_by_uuid(uuid)
    end

    def next_vmid
      node.servers.next_id
    end

    def node_id
      attrs[:node_id]
    end

    def node_id=(value)
      attrs[:node_id] = value
    end

    def node
      client.nodes.get node_id
    end

    def ssl_certs
      attrs[:ssl_certs]
    end

    def ssl_certs=(value)
      attrs[:ssl_certs] = value
    end

    def certs_to_store
      return if ssl_certs.blank?

      store = OpenSSL::X509::Store.new
      ssl_certs.split(/(?=-----BEGIN)/).each do |cert|
        x509_cert = OpenSSL::X509::Certificate.new cert
        store.add_cert x509_cert
      end
      store
    rescue StandardError => e
      logger.error(e)
      raise ::Foreman::Exception, N_('Unable to store X509 certificates')
    end

    def ssl_verify_peer
      attrs[:ssl_verify_peer].blank? ? false : Foreman::Cast.to_bool(attrs[:ssl_verify_peer])
    end

    def ssl_verify_peer=(value)
      attrs[:ssl_verify_peer] = value
    end

    def connection_options
      opts = http_proxy ? { proxy: http_proxy.full_url } : { disable_proxy: 1 }
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
      rescue StandardError => e
        logger.error(e)
        raise ::Foreman::Exception, _('%s console is not supported at this time') % type_console
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
      @client ||= ::Fog::Proxmox::Compute.new(fog_credentials)
    end

    def identity_client
      @identity_client ||= ::Fog::Proxmox::Identity.new(fog_credentials)
    end

    def network_client
      @network_client ||= ::Fog::Proxmox::Network.new(fog_credentials)
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
        kvm: 1,
        vga: 'std',
        memory: 512 * MEGA,
        ostype: 'l26',
        keyboard: 'en-us',
        cpu: 'kvm64',
        scsihw: 'virtio-scsi-pci',
        ide2: 'none,media=cdrom',
        templated: 0
      ).merge(Fog::Proxmox::DiskHelper.flatten(volume_server_defaults)).merge(Fog::Proxmox::DiskHelper.flatten(volume_container_defaults)).merge(Fog::Proxmox::NicHelper.flatten(interface_defaults))
    end

    def vm_container_instance_defaults
      ActiveSupport::HashWithIndifferentAccess.new(
        name: "foreman_#{Time.now.to_i}",
        vmid: next_vmid,
        type: 'lxc',
        node_id: node_id,
        memory: 512 * MEGA,
        templated: 0
      ).merge(Fog::Proxmox::DiskHelper.flatten(volume_container_defaults)).merge(Fog::Proxmox::DiskHelper.flatten(volume_server_defaults)).merge(Fog::Proxmox::NicHelper.flatten(interface_defaults))
    end

    def vm_instance_defaults
      super.merge(vmid: next_vmid, node_id: node_id)
    end

    def volume_server_defaults(controller = 'scsi', device = 0)
      id = "#{controller}#{device}"
      { id: id, storage: storages.first.identity.to_s, size: (8 * GIGA), options: { cache: 'none' } }
    end

    def volume_container_defaults(id = 'rootfs')
      { id: id, storage: storages.first.identity.to_s, size: (8 * GIGA), options: {} }
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
      operating_systems = ['other', 'solaris']
      operating_systems += available_linux_operating_systems
      operating_systems += available_windows_operating_systems
      operating_systems
    end

    def available_linux_operating_systems
      ['l24', 'l26', 'debian', 'ubuntu', 'centos', 'fedora', 'opensuse', 'archlinux', 'gentoo', 'alpine']
    end

    def available_windows_operating_systems
      ['wxp', 'w2k', 'w2k3', 'w2k8', 'wvista', 'win7', 'win8', 'win10']
    end

    def os_linux_types_mapping(host)
      ['Debian', 'Redhat', 'Suse', 'Altlinux', 'Archlinux', 'CoreOs', 'Gentoo'].include?(host.operatingsystem.type) ? available_linux_operating_systems : []
    end

    def os_windows_types_mapping(host)
      ['Windows'].include?(host.operatingsystem.type) ? available_windows_operating_systems : []
    end

    def host
      URI.parse(url).host
    end

    def save_find_vm_in_servers_by_uuid(servers, uuid)
      servers.get(uuid)
    rescue Fog::Errors::NotFound
      nil
    rescue StandardError => e
      Foreman::Logging.exception(format(_('Failed retrieving proxmox server vm by vmid=%<vmid>s'), vmid: uuid), e)
      raise(ActiveRecord::RecordNotFound)
    end
  end
end
