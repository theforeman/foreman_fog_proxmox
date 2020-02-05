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

require 'fog/proxmox/helpers/nic_helper'
require 'fog/proxmox/helpers/disk_helper'
require 'foreman_fog_proxmox/value'

module ForemanFogProxmox
  class Proxmox < ComputeResource
    include ProxmoxVmHelper
    include ProxmoxServerHelper
    include ProxmoxContainerHelper
    include ProxmoxConnection
    include ProxmoxTokenExpiration
    include ProxmoxVmNew
    include ProxmoxVmCommands
    include ProxmoxVmQueries
    include ProxmoxComputeAttributes
    include ProxmoxVolumes
    include ProxmoxInterfaces
    include ProxmoxImages
    include ProxmoxOperatingSystems
    include ProxmoxVersion
    include ProxmoxConsole
    validates :url, :format => { :with => URI::DEFAULT_PARSER.make_regexp }, :presence => true
    validates :user, :format => { :with => /(\w+)[@]{1}(\w+)/ }, :presence => true
    validates :password, :presence => true
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

    def associated_host(vm)
      associate_by('mac', vm.mac)
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

    def renew
      attrs[:renew].blank? ? false : Foreman::Cast.to_bool(attrs[:renew])
    end

    def renew=(value)
      attrs[:renew] = value
    end

    private

    def client
      @client ||= ::Fog::Proxmox::Compute.new(fog_credentials)
    end

    def identity_client
      @identity_client ||= ::Fog::Proxmox::Identity.new(fog_credentials)
    end

    def network_client
      @network_client ||= ::Fog::Proxmox::Network.new(fog_credentials)
    end

    def host
      URI.parse(url).host
    end
  end
end
