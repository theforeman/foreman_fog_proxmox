# frozen_string_literal: true

# Copyright 2021 Tristan Robert

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

module ProxmoxComputeResourcesVmsHelper
  def proxmox_vm_id(compute_resource, vm)
    id = vm.identity
    id = vm.unique_cluster_identity(compute_resource) if compute_resource.instance_of?(ForemanFogProxmox::Proxmox)
    id
  end

  def vm_host_action(vm)
    host = Host.for_vm_uuid(@compute_resource, vm).first
    return unless host

    display_link_if_authorized(_("Host"), hash_for_host_path(:id => host), :class => 'btn btn-default')
  end

  def vm_power_action(vm, authorizer = nil)
    opts = hash_for_power_compute_resource_vm_path(:compute_resource_id => @compute_resource, :id => proxmox_vm_id(@compute_resource, vm)).merge(
      :auth_object => @compute_resource, :permission => 'power_compute_resources_vms', :authorizer => authorizer
    )
    html = power_action_html(vm)

    display_link_if_authorized "Power #{action_string(vm)}", opts, html.merge(:method => :put)
  end

  def vm_associate_action(vm)
    vm_associate_link(vm, link_class: "btn btn-default")
  end

  def vm_associate_link(vm, link_class: "")
    return unless @compute_resource.supports_host_association?
    display_link_if_authorized(
      _('Associate VM'),
      hash_for_associate_compute_resource_vm_path(
        :compute_resource_id => @compute_resource,
        :id => proxmox_vm_id(@compute_resource, vm)
      ).merge(
        :auth_object => @compute_resource,
        :permission => 'edit_compute_resources'
      ),
      :title => _('Associate VM to a Foreman host'),
      :method => :put,
      :class => link_class
    )
  end

  def vm_import_action(vm, html_options = {})
    @_linked_hosts_cache ||= Host.where(:compute_resource_id => @compute_resource.id).pluck(:uuid)
    return if @_linked_hosts_cache.include?(proxmox_vm_id(@compute_resource, vm).to_s)

    import_managed_link = display_link_if_authorized(
      _('Import as managed Host'),
      hash_for_import_compute_resource_vm_path(
        :compute_resource_id => @compute_resource,
        :id => proxmox_vm_id(@compute_resource, vm),
        :type => 'managed'
      ),
      html_options
    )
    import_unmanaged_link = display_link_if_authorized(
      _('Import as unmanaged Host'),
      hash_for_import_compute_resource_vm_path(
        :compute_resource_id => @compute_resource,
        :id => proxmox_vm_id(@compute_resource, vm),
        :type => 'unmanaged'
      ),
      html_options
    )

    import_managed_link + import_unmanaged_link
  end

  def vm_console_action(vm)
    return unless vm.ready?

    link_to_if_authorized(
      _('Console'),
      hash_for_console_compute_resource_vm_path.merge(
        :auth_object => @compute_resource,
        :id => proxmox_vm_id(@compute_resource, vm)
      ),
      {
        :id => 'console-button',
        :class => 'btn btn-info',
      }
    )
  end

  def vm_delete_action(vm, authorizer = nil)
    display_delete_if_authorized(
      hash_for_compute_resource_vm_path(:compute_resource_id => @compute_resource, :id => proxmox_vm_id(@compute_resource, vm)).merge(
        :auth_object => @compute_resource, :authorizer => authorizer
      ), :class => 'btn btn-danger'
    )
  end
end
