# frozen_string_literal: true

# Copyright 2019 Tristan Robert

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
  module ProxmoxPools
    def pools
      pools = identity_client.pools.all
      pools.sort_by(&:poolid)
    end

    def pool_owner(vm)
      logger.debug("pool_owner(#{vm&.vmid})")
      pools_owners = pools.select { |pool| pool.has_server?(vm&.vmid) }
      pool = pools_owners.first
      logger.debug("found vm: #{vm&.vmid} member of pool: #{pool&.poolid}")
      vm&.config&.pool = pool&.poolid
    end

    def add_vm_to_pool(poolid, vmid)
      logger.debug("add_vm_to_pool(#{poolid}, #{vmid})")
      pool = identity_client.pools.get poolid
      pool&.add_server vmid
    end

    def remove_vm_from_pool(poolid, vmid)
      logger.debug("remove_vm_from_pool(#{poolid}, #{vmid})")
      pool = identity_client.pools.get poolid
      pool&.remove_server vmid
    end

    def update_pool(vm, poolid)
      pool_owner(vm)
      vm_pool = vm.config.pool || ''
      return if vm_pool.eql?(poolid)

      remove_vm_from_pool(vm_pool, vm.vmid)
      add_vm_to_pool(poolid, vm.vmid)
    end
  end
end
