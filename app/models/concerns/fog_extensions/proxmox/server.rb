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

module FogExtensions
  module Proxmox
    module Server
      extend ActiveSupport::Concern
      attr_accessor :image_id, :templated, :ostemplate_storage, :ostemplate_file, :password, :start_after_create

      def unique_cluster_identity(compute_resource)
        compute_resource.id.to_s + '_' + identity.to_s
      end

      def start
        action('start')
      end

      def stop
        action('stop')
      end

      def reboot
        stop
        start
      end

      def reset
        reboot
      end

      def mac
        config.mac_addresses.first
      end

      def memory
        maxmem.to_i
      end

      def state
        qmpstatus
      end

      delegate :description, to: :config

      def vm_description
        format(_('Type %<type>s, node %<node>s, %<cpus>s CPUs and %<memory>s MB memory'), type: type, node: node_id, cpus: config.cores || '0', memory: config.memory / (1024 * 1024) || '0')
      end

      def select_nic(fog_nics, nic)
        fog_nics.find { |fog_nic| fog_nic.identity.to_s == nic.compute_attributes[:id] }
      end

      delegate :interfaces, to: :config

      def nics
        config.interfaces.collect(&:to_s)
      end

      def volumes
        config.disks
      end

      def disks
        config.disks.collect(&:to_s)
      end

      delegate :vga, to: :config
      delegate :pool, to: :config
      delegate :cloud_init?, to: :config

      def interfaces_attributes=(attrs); end

      def volumes_attributes=(attrs); end

      def config_attributes=(attrs); end

      def templated?
        volumes.any?(&:template?)
      end

      def cdrom?
        volumes.any?(&:cdrom?)
      end
    end
  end
end
