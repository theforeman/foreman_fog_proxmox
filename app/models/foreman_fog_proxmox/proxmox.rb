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
    include ProxmoxVMHelper
    include ProxmoxConnection
    include ProxmoxVMNew
    include ProxmoxVMCommands
    include ProxmoxVMQueries
    include ProxmoxComputeAttributes
    include ProxmoxVolumes
    include ProxmoxInterfaces
    include ProxmoxImages
    include ProxmoxOperatingSystems
    include ProxmoxVersion
    include ProxmoxConsole
    validates :url, :format => { :with => URI::DEFAULT_PARSER.make_regexp }, :presence => true
    validates :auth_method, :presence => true, :inclusion => { in: ['access_ticket', 'user_token'],
      message: ->(value) do format('%<value>s is not a valid authentication method', { value: value }) end }
    validates :user, :format => { :with => /(\w+)@{1}(\w+)/ }, :presence => true
    validates :password, :presence => true, :if => :access_ticket?
    validates :token_id, :presence => true, :if => :user_token?
    validates :token, :presence => true, :if => :user_token?

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

    def associate_by(name, attributes)
      Host.authorized(:view_hosts,
        Host).joins(:primary_interface).where(:nics => { :primary => true }).where("nics.#{name}".downcase => attributes.downcase).readonly(false).first
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

    def auth_method
      attrs[:auth_method] || 'access_ticket'
    end

    def auth_method=(value)
      attrs[:auth_method] = value
    end

    def token_id
      attrs[:token_id]
    end

    def token_id=(value)
      attrs[:token_id] = value
    end

    def token
      attrs[:token]
    end

    def token=(value)
      attrs[:token] = value
    end

    private

    def fog_credentials
      hash = {
        proxmox_url: url,
        proxmox_auth_method: auth_method || 'access_ticket',
        connection_options: connection_options,
      }
      if access_ticket?
        hash[:proxmox_username] = user
        hash[:proxmox_password] = password
      end
      if user_token?
        hash[:proxmox_userid] = user
        hash[:proxmox_token] = token
        hash[:proxmox_tokenid] = token_id
      end
      hash
    end

    def token_expired?(e)
      e.response.reason_phrase == 'token expired'
    end

    def client
      @client ||= ::Fog::Proxmox::Compute.new(fog_credentials)
    rescue Excon::Errors::Unauthorized => e
      raise ::Foreman::Exception, 'User token expired' if token_expired?(e)
    rescue StandardError => e
      logger.warn("failed to create compute client: #{e}")
      raise ::Foreman::Exception, error_message(e)
    end

    def identity_client
      @identity_client ||= ::Fog::Proxmox::Identity.new(fog_credentials)
    rescue Excon::Errors::Unauthorized => e
      raise ::Foreman::Exception, 'User token expired' if token_expired?(e)
    rescue StandardError => e
      logger.warn("failed to create identity client: #{e}")
      raise ::Foreman::Exception, error_message(e)
    end

    def network_client
      @network_client ||= ::Fog::Proxmox::Network.new(fog_credentials)
    rescue Excon::Errors::Unauthorized => e
      raise ::Foreman::Exception, 'User token expired' if token_expired?(e)
    rescue StandardError => e
      logger.warn("failed to create network client: #{e}")
      raise ::Foreman::Exception, error_message(e)
    end

    def error_message(e)
      "Failed to create Proxmox compute resource: #{e.message}.
       Either provided credentials or FQDN is wrong or
       your server cannot connect to Proxmox due to network issues."
    end

    def proxmox_host
      URI.parse(url).host
    end
  end
end
