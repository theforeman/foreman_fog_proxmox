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
            attr_accessor :image_id, :templated, :ostemplate_storage, :ostemplate_file
            def to_s
                name
            end
            def persisted?
                !!identity && !!uptime
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
                config.memory * 1024 * 1024
            end
            def state
                qmpstatus
            end
            def description
                config.description
            end
            def vm_description
                "Name=#{name}, vmid=#{vmid}"
            end
            def select_nic(fog_nics, nic)
                fog_nics.find {|fog_nic| fog_nic.identity.to_s == nic.identifier}
            end
            def interfaces
                config.interfaces
            end
            def volumes
                config.disks.reject { |disk| disk.cdrom? }
            end
            def disks
                config.disks.collect { |disk| disk.id+': '+disk.volid }
            end
            def vga
                config.vga
            end
            def interfaces_attributes=(attrs); end
            def volumes_attributes=(attrs); end
            def config_attributes=(attrs); end
            def templated?
                volumes.any? { |volume| volume.templated? }
            end
        end
    end
end   