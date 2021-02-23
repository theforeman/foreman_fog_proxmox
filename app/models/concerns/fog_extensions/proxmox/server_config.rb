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

require 'fog/proxmox/helpers/cpu_helper'

module FogExtensions
  module Proxmox
    module ServerConfig
      extend ActiveSupport::Concern
      def cpu_type
        Fog::Proxmox::CpuHelper.extract_cputype(cpu)
      end

      Fog::Proxmox::CpuHelper.flags.each do |flag_key, flag_value|
        define_method(flag_key) do
          Fog::Proxmox::CpuHelper.flag_value(cpu, flag_value)
        end
      end

      def rootfs_storage
        disks.rootfs&.storage
      end

      def rootfs_file
        disks.rootfs&.volid
      end

      def cloud_init?
        disks.any?(&:cloud_init?)
      end
    end
  end
end
