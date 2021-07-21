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

module ForemanFogProxmox
  module ComputeResourcesVmsController
    extend ActiveSupport::Concern
    included do
      prepend Overrides
    end
    module Overrides
      def associate
        if Host.for_vm_uuid(@compute_resource, @vm).any?
          process_error(:error_msg => _("VM already associated with a host"), :redirect => compute_resource_vm_path(:compute_resource_id => params[:compute_resource_id], :id => proxmox_vm_id(@compute_resource, @vm)))
          return
        end
        host = @compute_resource.associated_host(@vm) if @compute_resource.respond_to?(:associated_host)
        if host.present?
          host.associate!(@compute_resource, @vm)
          process_success(:success_msg => _("VM associated to host %s") % host.name, :success_redirect => host_path(host))
        else
          process_error(:error_msg => _("No host found to associate this VM with"), :redirect => compute_resource_vm_path(:compute_resource_id => params[:compute_resource_id], :id => proxmox_vm_id(@compute_resource, @vm)))
        end
      end

      def console
        @console = @compute_resource.console proxmox_vm_id(@compute_resource, @vm)
        render case @console[:type]
               when 'spice'
                 'hosts/console/spice'
               when 'vnc'
                 'hosts/console/vnc'
               when 'vmrc'
                 'hosts/console/vmrc'
               else
                 'hosts/console/log'
               end
      rescue StandardError => e
        process_error :redirect => compute_resource_vm_path(@compute_resource, proxmox_vm_id(@compute_resource, @vm)), :error_msg => (_("Failed to set console: %s") % e), :object => @vm
      end

      private

      def proxmox_vm_id(compute_resource, vm)
        id = vm.identity
        id = vm.unique_cluster_identity(compute_resource) if compute_resource.class == ForemanFogProxmox::Proxmox
        id
      end

      def run_vm_action(action)
        if @vm.send(action)
          @vm.reload
          success format(_("%<vm>s is now %<vm_state>s"), { :vm => @vm, :vm_state => @vm.state.capitalize })
        else
          error format(_("failed to %<action>s %<vm>s"), { :action => _(action), :vm => @vm })
        end
        redirect_back(:fallback_location => compute_resource_vm_path(:compute_resource_id => params[:compute_resource_id], :id => proxmox_vm_id(@compute_resource, @vm)))
      # This should only rescue Fog::Errors, but Fog returns all kinds of errors...
      rescue StandardError => e
        error format(_("Error - %<message>s"), { :message => _(e.message) })
        redirect_back(:fallback_location => compute_resource_vm_path(:compute_resource_id => params[:compute_resource_id], :id => proxmox_vm_id(@compute_resource, @vm)))
      end
    end
  end
end
