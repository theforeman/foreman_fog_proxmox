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

require 'foreman_fog_proxmox/semver'

module ForemanFogProxmox
  class SemverTest < ActiveSupport::TestCase
    describe 'semver?' do
      it '#5.3.2 returns true' do
        assert ForemanFogProxmox::Semver.semver?('5.3.2')
      end
      it '#6.0-6 returns true' do
        assert ForemanFogProxmox::Semver.semver?('6.0-6')
      end
      it '#5.3beta returns false' do
        assert_not ForemanFogProxmox::Semver.semver?('5.3beta')
      end
    end
    describe 'to_semver' do
      it '#5.3.2 returns SemverClass' do
        semver = ForemanFogProxmox::Semver.to_semver('5.3.2')
        assert_not_nil semver
        assert semver.is_a?(ForemanFogProxmox::Semver::SemverClass)
        assert_equal 5, semver.major
        assert_equal 3, semver.minor
        assert_equal 2, semver.patch
        assert_equal '', semver.qualifier
      end
      it '#6.0-6 returns SemverClass' do
        semver = ForemanFogProxmox::Semver.to_semver('6.0-6')
        assert_not_nil semver
        assert semver.is_a?(ForemanFogProxmox::Semver::SemverClass)
        assert_equal 6, semver.major
        assert_equal 0, semver.minor
        assert_equal 0, semver.patch
        assert_equal '6', semver.qualifier
      end
      it '#5.3beta raises ArgumentError' do
        assert_raises ArgumentError do
          ForemanFogProxmox::Semver.to_semver('5.3beta')
        end
      end
    end
    # rubocop:disable Lint/UselessComparison
    describe 'semverclass comparators' do
      it '#5.3.0 <= 5.4.3 returns true' do
        assert ForemanFogProxmox::Semver.to_semver('5.3.0') <= ForemanFogProxmox::Semver.to_semver('5.4.3')
      end
      it '#5.3.0 <= 6.0.1 returns true' do
        assert ForemanFogProxmox::Semver.to_semver('5.3.0') <= ForemanFogProxmox::Semver.to_semver('6.0.1')
      end
      it '#5.4.3 < 6.1.0 returns true' do
        assert ForemanFogProxmox::Semver.to_semver('5.4.3') < ForemanFogProxmox::Semver.to_semver('6.1.0')
      end
      it '#6.0.1 < 6.1.0 returns true' do
        assert ForemanFogProxmox::Semver.to_semver('6.0.1') < ForemanFogProxmox::Semver.to_semver('6.1.0')
      end
      it '#2.4.0 >= 1.3.0 returns true' do
        assert ForemanFogProxmox::Semver.to_semver('2.4.0') >= ForemanFogProxmox::Semver.to_semver('1.3.0')
      end
      it '#1.0.10 <= 1.0.20 returns true' do
        assert ForemanFogProxmox::Semver.to_semver('1.0.10') <= ForemanFogProxmox::Semver.to_semver('1.0.20')
      end
      it '#1.2.3-beta == 1.2.3-beta returns true' do
        assert ForemanFogProxmox::Semver.to_semver('1.2.3-beta') == ForemanFogProxmox::Semver.to_semver('1.2.3-beta')
      end
      it '#1.2.3-beta >= 1.-beta raises ArgumentError' do
        assert_raises ArgumentError do
          ForemanFogProxmox::Semver.to_semver('1.2.3-beta') >= ForemanFogProxmox::Semver.to_semver('1.-beta')
        end
      end
      it '#SemverClass(1.2.3-beta) >= String(1.-beta) raises TypeError' do
        assert_raises TypeError do
          ForemanFogProxmox::Semver.to_semver('1.2.3-beta') >= '1.-beta'
        end
      end
      it '#1.10.2 < 1.20.0 returns true' do
        assert ForemanFogProxmox::Semver.to_semver('1.10.2') < ForemanFogProxmox::Semver.to_semver('1.20.0')
      end
      it '#0.10.2 < 1.20.0 returns true' do
        assert_equal 0, ForemanFogProxmox::Semver.to_semver('0.10.2').major
        assert_equal 10, ForemanFogProxmox::Semver.to_semver('0.10.2').minor
        assert_equal 2, ForemanFogProxmox::Semver.to_semver('0.10.2').patch
        assert_equal 1, ForemanFogProxmox::Semver.to_semver('1.20.0').major
        assert_equal 20, ForemanFogProxmox::Semver.to_semver('1.20.0').minor
        assert_equal 0, ForemanFogProxmox::Semver.to_semver('1.20.0').patch
        assert ForemanFogProxmox::Semver.to_semver('0.10.2').major < ForemanFogProxmox::Semver.to_semver('1.20.0').major
        assert_equal false, ForemanFogProxmox::Semver.to_semver('0.10.2').major == ForemanFogProxmox::Semver.to_semver('1.20.0').major
        assert_equal false, ForemanFogProxmox::Semver.to_semver('0.10.2').minor == ForemanFogProxmox::Semver.to_semver('1.20.0').minor
        assert ForemanFogProxmox::Semver.to_semver('0.10.2').minor < ForemanFogProxmox::Semver.to_semver('1.20.0').minor
        assert ForemanFogProxmox::Semver.to_semver('0.10.2').patch > ForemanFogProxmox::Semver.to_semver('1.20.0').patch
        assert ForemanFogProxmox::Semver.to_semver('0.10.2') < ForemanFogProxmox::Semver.to_semver('1.20.0')
      end
    end
    # rubocop:enable Lint/UselessComparison
  end
end
