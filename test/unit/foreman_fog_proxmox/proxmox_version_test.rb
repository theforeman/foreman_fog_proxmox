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

require 'test_plugin_helper'
require 'models/compute_resources/compute_resource_test_helpers'
require 'active_support/core_ext/hash/indifferent_access'

module ForemanFogProxmox
  class ProxmoxVersionTest < ActiveSupport::TestCase
    include ComputeResourceTestHelpers
    include ProxmoxVmHelper

    wrong_version = { version: '5.a', release: '1' }.with_indifferent_access
    supported_version = { version: '5.4', release: '3' }.with_indifferent_access
    supported_6_version = { version: '6.0', release: '1' }.with_indifferent_access
    supported_6_1_version = { version: '6.1', release: '3' }.with_indifferent_access
    unsupported_version = { version: '5.2', release: '2' }.with_indifferent_access

    describe 'version' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
        @identity_client = mock('identity_client')
        @cr.stubs(:identity_client).returns(@identity_client)
      end

      it 'returns 5.a.1 with 5.a-1' do
        @identity_client.stubs(:read_version).returns(wrong_version)
        assert_equal '5.a.1', @cr.version
      end

      it 'returns 5.4.3 with 5.4-3' do
        @identity_client.stubs(:read_version).returns(supported_version)
        assert_equal '5.4.3', @cr.version
      end

      it 'returns 5.2.2 with 5.2-2' do
        @identity_client.stubs(:read_version).returns(unsupported_version)
        assert_equal '5.2.2', @cr.version
      end
    end

    describe 'version_suitable?' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
        @identity_client = mock('identity_client')
        @cr.stubs(:identity_client).returns(@identity_client)
      end

      it 'raises error with 5.a.1' do
        @identity_client.stubs(:read_version).returns(wrong_version)
        err = assert_raises Foreman::Exception do
          @cr.version_suitable?
        end
        assert err.message.end_with?('Proxmox version 5.a.1 is not semver suitable')
      end

      it 'is true with 5.4-3' do
        @identity_client.stubs(:read_version).returns(supported_version)
        assert_equal true, @cr.version_suitable?
      end

      it 'is true with 6.0-1' do
        @identity_client.stubs(:read_version).returns(supported_6_version)
        assert_equal true, @cr.version_suitable?
      end

      it 'is true with 6.1-3' do
        @identity_client.stubs(:read_version).returns(supported_6_1_version)
        assert_equal true, @cr.version_suitable?
      end

      it 'is false with 5.2-2' do
        @identity_client.stubs(:read_version).returns(unsupported_version)
        assert_equal false, @cr.version_suitable?
      end
    end
  end
end
