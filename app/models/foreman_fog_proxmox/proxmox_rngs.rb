# frozen_string_literal: true

# This file is part of ForemanFogProxmox.

# ForemanFogProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# ForemanFogProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with ForemanFogProxmox. If not, see <http://www.gnu.org/licenses/>.

module ForemanFogProxmox
  module ProxmoxRngs
    include ProxmoxVMHelper

    def delete_rng(vm_obj)
      logger.info("vm #{vm_obj.identity} delete rng0")
      vm_obj.update(delete: 'rng0')
    end

    def process_rng_removal(vm_obj, attributes)
      return unless vm_obj.type == 'qemu'
      return if vm_obj.config.rng.blank?
      return if attributes['rng_attributes'].present?

      logger.debug("Removing rng from VM #{vm_obj}")
      delete_rng(vm_obj)
    end
  end
end
