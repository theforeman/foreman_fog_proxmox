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

module ProxmoxComputeHelper
  def compute_attribute_map(params, compute_resource, new)
    if controller_name == 'hosts'
      attribute_map = hosts_controller_compute_attribute_map(params, compute_resource, new)
    elsif controller_name == 'compute_attributes'
      attribute_map = compute_resource_controller_attribute_map(params, compute_resource)
    end
    attribute_map
  end

  private

  def hosts_controller_compute_attribute_map(_params, _compute_resource, new)
    attribute_map = empty_attribute_map
    if new.try(:new_record?)
      attribute_map = empty_attribute_map
    elsif new
      attribute_map[:cpu_count]  = new.vcpus_max ? new.vcpus_max : nil
      attribute_map[:memory_min] = new.memory_static_min ? new.memory_static_min : nil
      attribute_map[:memory_max] = new.memory_static_max ? new.memory_static_max : nil
      if new.config.ides
        ide = new.config.ides.first
        if ide
          attribute_map[:storage_selected] = ide.storage ? disk_image.storage : nil
          attribute_map[:bus_selected] = disk_image.id ? vdi.sr.uuid : nil
          attribute_map[:device_selected] = vdi.sr.uuid ? vdi.sr.uuid : nil
          attribute_map[:cache_selected] = vdi.sr.uuid ? vdi.sr.uuid : nil
          attribute_map[:volume_size] = vdi.virtual_size ? (vdi.virtual_size.to_i / 1_073_741_824).to_s : nil
        end
      end
      if new.config.nics
        attribute_map[:network_selected] = new.config.nics.first.id ? new.config.nics.first.id : nil
      end
    end
    attribute_map
  end

  def compute_resource_controller_attribute_map
    empty_attribute_map
  end

  def empty_attribute_map
    { :volume_size => nil,
      :node_selected => nil,
      :storage_selected => nil,
      :device_selected => nil,
      :bus_selected => nil,
      :cache_selected => nil,
      :network_selected => nil }
  end

  def proxmox_storages_map(compute_resource)
    compute_resource.storages.map { |storage| [storage.comment, storage.storage] }
  end

  def proxmox_nodes_map(compute_resource)
    compute_resource.available_nodes!.map { |node| [node.node, node.node] }
  end

  def selectable_f_with_cache_invalidation(f, attr, array,
                                           select_options = {}, html_options = {}, input_group_options = {})
    unless html_options.key?('input_group_btn')
      html_options[:input_group_btn] = link_to_function(
        icon_text('refresh'),
        "refreshCache(this, #{input_group_options[:callback]})",
        :class => 'btn btn-primary',
        :title => _(input_group_options[:title]),
        :data  => {
          :url                 => input_group_options[:url],
          :compute_resource_id => input_group_options[:computer_resource_id],
          :attribute           => input_group_options[:attribute]
        }
      )
    end
    selectable_f(f, attr, array, select_options, html_options)
  end
end
