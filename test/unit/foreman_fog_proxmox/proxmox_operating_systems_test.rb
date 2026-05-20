# frozen_string_literal: true

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

module ForemanFogProxmox
  class ProxmoxOperatingSystemsTest < ActiveSupport::TestCase
    def setup
      @cr = FactoryBot.build_stubbed(:proxmox_cr)
    end

    test '#compute_os_types returns linux os types for linux families' do
      assert_equal @cr.available_linux_operating_systems, @cr.compute_os_types(host_with_os_type('Debian'))
    end

    test '#compute_os_types returns windows os types for windows family' do
      assert_equal @cr.available_windows_operating_systems, @cr.compute_os_types(host_with_os_type('Windows'))
    end

    test '#compute_os_types returns other os type for Freebsd family' do
      assert_equal ['other'], @cr.compute_os_types(host_with_os_type('Freebsd'))
    end

    test '#compute_os_types returns solaris os type for Solaris family' do
      assert_equal ['solaris'], @cr.compute_os_types(host_with_os_type('Solaris'))
    end

    private

    def host_with_os_type(type)
      stub(operatingsystem: stub(type: type))
    end
  end
end
