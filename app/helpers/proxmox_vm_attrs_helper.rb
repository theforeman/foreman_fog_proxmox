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
require 'fog/proxmox/helpers/cpu_helper'
require 'foreman_fog_proxmox/value'
require 'foreman_fog_proxmox/hash_collection'

# Convert a foreman form server hash into a fog-proxmox server attributes hash
module ProxmoxVmAttrsHelper
  def object_to_attributes_hash(vm)
    vm_h = ActiveSupport::HashWithIndifferentAccess.new
    keys = [ :vmid, :node_id, :type]
    main = vm.attributes.select { |key, _value| keys.include? key }
    config = vm.config.all_attributes
    general = [:pool, :description]
    main.merge!(config.select {|key, _value| general.include? key})
    opts = [:boot, :vga, :bios, :scsihw, :kvm, :agent, :ostype, :onboot]
    options = config.select {|key, _value| opts.include? key}
    cpu = [:cpu_type, :cpulimit, :cpuunits, :vcpus, :cores, :sockets, :numa]
    cpu_opts = config.select {|key, _value| cpu.include? key}
    memory = [:memory, :balloon, :shares]
    mem_opts = config.select {|key, _value| memory.include? key}
    hw = {'cpus': cpu_opts, 'memory': mem_opts}
    cloudinit_opts = [:volid, :storage_type, :storage, :controller, :device]
    cloudinit = config.select {|key, _value| [:ciuser, :cipassword, :searchdomain, :nameserver, :sshkeys].include? key}
    hdd_opts = [:volid, :storage_type, :storage, :controller, :device, :cache, :size]
    cdrom_opts = [:storage_type, :cdrom, :storage, :volid]
    storage = {'hdd': hdd_opts, 'cdrom': cdrom_opts, 'cloudinitVal': cloudinit, 'cloudinit': cloudinit_opts,  'disks': config[:disks] }
    network = [:id, :model, :bridge, :tag, :rate, :queues, :firewall, :link_down]
    nics = {'nic': network, 'interfaces': config[:interfaces]}
    attributes = {'general': main, 'options': options, 'hw': hw, 'storage': storage, 'network': nics }
    logger
    vm_h = vm_h.merge(attributes)
  end
end
