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

module ForemanFogProxmox
  module ProxmoxNodeMockFactory
    def mock_node_servers(cr, servers)
      node = mock('node')
      node.stubs(:servers).returns(servers)
      cr.stubs(:nodes).returns([node])
      cr.stubs(:node).returns(node)
      cr
    end

    def mock_node_containers(cr, containers)
      node = mock('node')
      node.stubs(:containers).returns(containers)
      cr.stubs(:node).returns(node)
      cr.stubs(:nodes).returns([node])
      cr
    end

    def mock_node_servers_containers(cr, servers, containers)
      node = mock('node')
      node.stubs(:containers).returns(containers)
      node.stubs(:servers).returns(servers)
      cr.stubs(:node).returns(node)
      cr.stubs(:nodes).returns([node])
      cr
    end

    def mock_cluster_nodes_servers_containers(cr, n1s, n1c, n2s, n2c)
      node1 = mock('node')
      node1.stubs(:node).returns('node1')
      node1.stubs(:servers).returns(n1s)
      node1.stubs(:containers).returns(n1c)
      node2 = mock('node')
      node2.stubs(:node).returns('node2')
      node2.stubs(:servers).returns(n2s)
      node2.stubs(:containers).returns(n2c)
      cr.stubs(:node).returns(node1)
      cr.stubs(:nodes).returns([node1, node2])
      cr
    end
  end
end
