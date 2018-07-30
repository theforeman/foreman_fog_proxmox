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
require 'fog/proxmox/helpers/nic_helper'

module ProxmoxVmHelper

  def object_to_hash(vm)
    vm_h = ActiveSupport::HashWithIndifferentAccess.new
    main_a = %w[name type node vmid]
    main_a += [:name, :type, :node, :vmid]
    main = vm.config.attributes.select { |key,_value| main_a.include? key }
    disks_regexp = /^(scsi|sata|mp|rootfs|virtio|ide)(\d+)/
    nics_regexp = /^(net)(\d+)/
    main_a += %w[templated]
    config = vm.config.attributes.reject { |key,_value| main_a.include?(key) || disks_regexp.match(key) || nics_regexp.match(key)  }
    vm_h = vm_h.merge(main)
    interfaces = {}
    vm.config.interfaces.each.each_with_index { |interface,i| interfaces.store(i.to_s, Fog::Proxmox::NicHelper.flatten(interface.attributes)) }
    vm_h = vm_h.merge({'interfaces_attributes': interfaces})
    volumes = {}
    disks_volumes = vm.config.disks.reject { |disk| disk.id == 'ide2' }
    disks_volumes.each.each_with_index { |disk,i| volumes.store(i.to_s, Fog::Proxmox::DiskHelper.flatten(disk.attributes)) }
    vm_h = vm_h.merge({'volumes_attributes': volumes})
    cd_disks = vm.config.disks.select { |disk| disk.id == 'ide2' }
    cdrom = {}
    disk_to_cdrom(cd_disks.first,cdrom)
    config = config.merge(cdrom)
    vm_h = vm_h.merge({'config_attributes': config})
    vm_h
  end

  def disk_to_cdrom(disk,cdrom)
    volid = disk.volid  
    cdrom_a = %w[none cdrom]  
    if cdrom_a.include? volid
      cdrom.store('cdrom',volid)
    else
      cdrom.store('cdrom','image')
      cdrom.store('cdrom_iso',volid)
      cdrom.store('cdrom_storage',disk.storage)
    end
  end

  def password_proxmox_f(f, attr, options = {})
    unset_button = options.delete(:unset)
    value = f.object[attr] if options.delete(:keep_value)
    password_field_tag(:fakepassword, value, :style => 'display: none', :autocomplete => 'new-password-fake') +
        field(f, attr, options) do
          options[:autocomplete]   ||= 'new-password'
          options[:placeholder]    ||= password_proxmox_placeholder(f.object, attr)
          options[:disabled] = true if unset_button
          options[:value] = value if value.present?
          addClass options, 'form-control'
          pass = f.password_field(attr, options) +
              '<span class="glyphicon glyphicon-warning-sign input-addon"
             title="'.html_safe + _('Caps lock ON') +
              '" style="display:none"></span>'.html_safe
          if unset_button
            button = link_to_function(icon_text("edit", "", :kind => "pficon"), 'toggle_input_group(this)', {:id => 'disable-pass-btn', :class => 'btn btn-default', :title => _("Change the password")})
            input_group(pass, input_group_btn(button))
          else
            pass
          end
        end
  end

  def password_proxmox_placeholder(obj, attr = nil)
    pass = obj.attributes.has_key?(attr)
    pass ? "********" : ''
  end


end