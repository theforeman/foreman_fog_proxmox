# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of ForemanProxmox.

# ForemanProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanProxmox. If not, see <http://www.gnu.org/licenses/>.

module FogExtensions
  module Proxmox
    module Server
      extend ActiveSupport::Concern

      include ActionView::Helpers::NumberHelper
      has_one :config

      def to_s
        name
      end

      def nics_attributes=(_attrs)
        config.nics
      end

      def volumes_attributes=(_attrs)
        config.disk_images
      end

      def cpu_type
        config.cpu_type
      end

      def mac
        config.mac_addresses.first
      end

      def state
        status
      end

      def vm_description
        format(_('%{cpus} CPUs and %{ram} memory'), :cpus => config.sockets * config.cores, :ram => number_to_human_size(config.memory.to_i))
      end

      def interfaces
        config.nics
      end

      def select_nic(fog_nics, _nic)
        fog_nics[0]
      end
    end
  end
end
