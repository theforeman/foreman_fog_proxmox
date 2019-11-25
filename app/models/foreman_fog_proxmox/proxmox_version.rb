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

require 'foreman_fog_proxmox/semver'

module ForemanFogProxmox
  module ProxmoxVersion
    def version_suitable?
      logger.debug(format(_('Proxmox compute resource version is %<version>s'), version: version))
      raise ::Foreman::Exception, format(_('Proxmox version %<version>s is not semver suitable'), version: version) unless ForemanFogProxmox::Semver.semver?(version)

      ForemanFogProxmox::Semver.to_semver(version) >= ForemanFogProxmox::Semver.to_semver('5.3.0') && ForemanFogProxmox::Semver.to_semver(version) < ForemanFogProxmox::Semver.to_semver('6.1.0')
    end

    def version
      v = identity_client.read_version
      "#{v['version']}.#{v['release']}"
    end
  end
end
