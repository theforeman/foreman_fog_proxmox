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

module NodeDashboardHelper
  def compute_data(statistics)
    data = []
    statistics.each do |statistic|
      t = Time.zone.at(statistic['time'])
      x = t.hour.to_s + ':' + t.min.to_s
      data << [x, statistic['loadavg'] * 100]
    end
    data
  end

  def render_node_statistics(statistics, options = {})
    data = compute_data(statistics)
    flot_bar_chart('node_statistics', _('Time'), _('Average load (x100)'), data, options)
  end
end
