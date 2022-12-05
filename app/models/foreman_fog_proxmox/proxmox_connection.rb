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

require 'fog/proxmox'

module ForemanFogProxmox
  module ProxmoxConnection
    def connection_options
      opts = super
      opts.store(:ssl_verify_peer, ssl_verify_peer)
      opts.store(:ssl_cert_store, certs_to_store) if Foreman::Cast.to_bool(ssl_verify_peer)
      opts
    end

    def access_ticket?
      auth_method == 'access_ticket'
    end

    def user_token?
      auth_method == 'user_token'
    end

    def credentials_valid?
      errors[:url].empty? && errors[:auth_method].empty?
      if access_ticket?
        errors[:user].empty? && errors[:user].include?('@') && errors[:password].empty? && errors[:node_id].empty?
      end
      if user_token?
        errors[:user].empty? && errors[:user].include?('@') && errors[:token_id].empty? && errors[:token].empty? && errors[:node_id].empty?
      end
    end

    def current_user_token_expire
      identity_client ? identity_client.expires : 0
    end

    def test_connection(options = {})
      super
      credentials_valid?
      identity_client
      version_suitable?
    rescue StandardError => e
      errors[:base] << e.message
      if e.message.include?('SSL')
        errors[:ssl_certs] << e.message
      else
        errors[:url] << e.message
      end
    end

    def disconnect
      client.terminate if @client
      @client = nil
      identity_client.terminate if @identity_client
      @identity_client = nil
      network_client.terminate if @network_client
      @network_client = nil
    end
  end
end
