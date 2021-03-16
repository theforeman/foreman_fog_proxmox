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

module Orchestration
  module Proxmox
    module Compute
      extend ActiveSupport::Concern

      def setComputeUpdate
        logger.info "Update Proxmox Compute instance for #{name}"
        final_compute_attributes = compute_attributes.merge(compute_resource.host_compute_attrs(self))
        logger.debug("setComputeUpdate: final_compute_attributes=#{final_compute_attributes}")
        compute_resource.save_vm uuid, final_compute_attributes
      rescue StandardError => e
        failure format(_('Failed to update a compute %<compute_resource>s instance %<name>s: %<e>s'), :compute_resource => compute_resource, :name => name, :e => e), e
      end

      def delComputeUpdate
        logger.info "Undo Update Proxmox Compute instance for #{name}"
        final_compute_attributes = old.compute_attributes.merge(compute_resource.host_compute_attrs(old))
        compute_resource.save_vm uuid, final_compute_attributes
      rescue StandardError => e
        failure format(_('Failed to undo update compute %<compute_resource>s instance %<name>s: %<e>s'), :compute_resource => compute_resource, :name => name, :e => e), e
      end

      def empty_provided_ips?(ip, ip6)
        ip.blank? && ip6.blank? && (compute_provides?(:ip) || compute_provides?(:ip6))
      end

      def ips_keys
        [:ip, :ip6]
      end

      def computeIp(foreman_attr, fog_attr)
        vm.send(fog_attr) || find_address(foreman_attr)
      end

      def computeValue(foreman_attr, fog_attr)
        value = ''
        value += compute_resource.id.to_s + '_' if foreman_attr == :uuid
        value += vm.send(fog_attr)
        value
      end

      def setVmDetails
        attrs = compute_resource.provided_attributes
        result = true
        attrs.each do |foreman_attr, fog_attr|
          if foreman_attr == :mac
            result = false unless match_macs_to_nics(fog_attr)
          elsif ips_keys.include?(foreman_attr)
            value = computeIp(foreman_attr, fog_attr)
            send("#{foreman_attr}=", value)
            result = false if send(foreman_attr).present? && !validate_foreman_attr(value, ::Nic::Base, foreman_attr)
          else
            value = computeValue(foreman_attr, fog_attr)
            send("#{foreman_attr}=", value)
            result = false unless validate_required_foreman_attr(value, Host, foreman_attr)
          end
        end
        return failure(format(_('Failed to acquire IP addresses from compute resource for %<name>s'), name: name)) if empty_provided_ips?(ip, ip6)

        result
      end

      def setComputeDetails
        if vm
          setVmDetails
        else
          failure format(_('failed to save %<name>s'), name: name)
        end
      end
    end
  end
end
