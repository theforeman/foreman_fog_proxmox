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
  module ProxmoxConsole
    def console(uuid)
      vm = find_vm_by_uuid(uuid)
      options = {}
      if vm.container?
        type_console = 'vnc'
        options.store(:console, type_console)
      else
        type_console = vm.config.type_console
      end
      options.store(:websocket, 1) if type_console == 'vnc'
      begin
        vnc_console = vm.start_console(options)
        WsProxy.start(:host => host, :host_port => vnc_console['port'], :password => vnc_console['ticket']).merge(:name => vm.name, :type => type_console)
      rescue StandardError => e
        logger.error(e)
        raise ::Foreman::Exception, _('%<s>s console is not supported at this time') % type_console
      end
    end
  end
end
