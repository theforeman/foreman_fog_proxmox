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

require 'fog/proxmox/helpers/disk_helper'

module FogExtensions
  module Proxmox
    module Disk
      extend ActiveSupport::Concern

      attr_accessor :ciuser, :cipassword, :searchdomain, :nameserver, :sshkeys

      def storage_type
        return 'cdrom' if cdrom?

        cloud_init? ? 'cloud_init' : 'hard_disk'
      end

      def cdrom
        return 'none' unless cdrom? || volid.nil?

        ['none', 'cdrom'].include?(volid) ? volid : 'image'
      end

      def cloudinit
        cloud_init? ? 'disk' : 'none'
      end

      def size_gb
        Fog::Proxmox::DiskHelper.to_int_gb(size)
      end
    end
  end
end
