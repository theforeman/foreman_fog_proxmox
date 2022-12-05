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

module ForemanFogProxmox
  module ProxmoxOperatingSystems
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
      if ['Debian', 'Redhat', 'Suse', 'Altlinux', 'Archlinux', 'Coreos', 'Rancheros',
          'Gentoo'].include?(host.operatingsystem.type)
        available_linux_operating_systems
      else
        []
      end
    end

    def os_windows_types_mapping(host)
      ['Windows'].include?(host.operatingsystem.type) ? available_windows_operating_systems : []
    end
  end
end
