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

      def secure_boot?
        attrs = attributes.with_indifferent_access
        secure_boot = attrs[:is_secure_boot]
        return Foreman::Cast.to_bool(secure_boot) ? '1' : '0' if attrs.key?(:is_secure_boot)

        secure_boot = bios == 'ovmf' && Foreman::Cast.to_bool(efidisk&.pre_enrolled_keys)
        Foreman::Cast.to_bool(secure_boot) ? '1' : '0'
      end

      def feature_nesting
        features_options['nesting']
      end

      def feature_keyctl
        features_options['keyctl']
      end

      def feature_fuse
        features_options['fuse']
      end

      def feature_mount
        features_options['mount']
      end

      private

      # Parse the Proxmox 'features' string (e.g. 'nesting=1,keyctl=1,mount=nfs')
      # into a hash so the individual feature fields round-trip on read. Guarded
      # with respond_to? so it also works against fog-proxmox versions that do
      # not yet declare the 'features' attribute.
      def features_options
        return {} unless respond_to?(:features) && features

        features.to_s.split(',').each_with_object({}) do |part, options|
          key, value = part.split('=', 2)
          options[key] = value
        end
      end
    end
  end
end
