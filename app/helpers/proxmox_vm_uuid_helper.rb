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

module ProxmoxVmUuidHelper
  UUID_REGEXP = /(?<cluster_id>\d+)_(?<vmid>\d+)/.freeze
  def extract(uuid, name)
    captures_h = uuid ? UUID_REGEXP.match(uuid.to_s) : { cluster_id: '', vmid: '' }
    captures_h ? captures_h[name] : ''
  end

  def match_uuid?(uuid)
    extract(uuid, :cluster_id) != ''
  end

  def extract_vmid(uuid)
    extract(uuid, :vmid)
  end
end
