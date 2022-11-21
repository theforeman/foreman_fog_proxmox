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

require 'test_plugin_helper'

module ForemanFogProxmox
  class ProxmoxVmNormalizeTest < ActiveSupport::TestCase
    describe 'complete_with_default_attributes' do
      before do
        @cr = FactoryBot.build_stubbed(:proxmox_cr)
      end

      it 'new server with attr rootfs empty' do
        attr = { "type" => "qemu", "node_id" => "pve", "vmid" => "100", "start_after_create" => "0", "pool" => "",
                 "config_attributes" =>
                  {
                    "description" => "", "boot" => "", "onboot" => "0",
                    "agent" => "0", "kvm" => "0", "vga" => "std", "scsihw" => "virtio-scsi-pci",
                    "bios" => "seabios", "cpu_type" => "kvm64", "numa" => "0", "spectre" => "0",
                    "pcid" => "0", "ssbd" => "0", "ibpb" => "0", "virt_ssbd" => "0", "amd_ssbd" => "0",
                    "amd_no_ssb" => "0", "md_clear" => "0", "pdpe1gb" => "0", "hv_tlbflush" => "0", "aes" => "0",
                    "hv_evmcs" => "0", "ostype" => "l26"
                  },
                 "volumes_attributes" =>
                  {
                    "0" =>
                     {
                       "_delete" => "", "storage_type" => "hard_disk",
                       "storage" => "local-lvm", "controller" => "virtio", "device" => "0", "cache" => "", "id" => "virtio0"
                     },
                    "1" => { "id" => "rootfs" }
                  },
                 "interfaces_attributes" =>
                  {
                    "0" =>
                     {
                       "id" => "net0",
                       "compute_attributes" =>
                        {
                          "model" => "virtio", "bridge" => "vmbr0"
                        }
                     }
                  } }.deep_symbolize_keys
        options = { "name" => "foreman_#{Time.now.to_i}", "vmid" => "100", "node_id" => "pve", "type" => "qemu",
                    "config_attributes" => {
                      "description" => "",
                      "boot" => "",
                      "onboot" => "0", "agent" => "0", "kvm" => "0", "vga" => "std",
                      "scsihw" => "virtio-scsi-pci", "bios" => "seabios", "cpu_type" => "kvm64",
                      "numa" => "0", "spectre" => "0",
                      "pcid" => "0", "ssbd" => "0", "ibpb" => "0", "virt_ssbd" => "0",
                      "amd_ssbd" => "0",
                      "amd_no_ssb" => "0", "md_clear" => "0", "pdpe1gb" => "0", "hv_tlbflush" => "0", "aes" => "0", "hv_evmcs" => "0",
                      "ostype" => "l26"
                    },
                    "volumes_attributes" =>
                    {
                      "0" =>
                      {
                        "_delete" => "", "storage_type" => "hard_disk", "storage" => "local-lvm",
                        "controller" => "virtio", "device" => "0", "cache" => "", "id" => "virtio0"
                      },
                      "1" =>
                      {
                        "storage" => "local-vm", "size" => 8_589_934_592, "storage_type" => "rootfs", "id" => "rootfs", "options" => {}
                      }
                    },
                    "interfaces_attributes" => { "0" => { "id" => "net0", "compute_attributes" => { "model" => "virtio", "bridge" => "vmbr0" } } }, "start_after_create" => "0", "pool" => "" }.deep_symbolize_keys
        node = mock('node')
        servers = mock('servers')
        storages = mock('storages')
        bridges = mock('bridges')
        bridge = mock('bridge')
        bridge.stubs(:identity).returns('vmbr0')
        storage = mock('storage')
        storage.stubs(:first).returns(storage)
        storage.stubs(:identity).returns('local-vm')
        storages.stubs(:first).returns(storage)
        bridges.stubs(:first).returns(bridge)
        servers.stubs(:next_id).returns(100)
        node.stubs(:servers).returns(servers)
        node.stubs(:node).returns('pve')
        nodes = mock('nodes')
        nodes.stubs(:first).returns(node)
        @cr.stubs(:nodes).returns(nodes)
        @cr.stubs(:storages).returns(storages)
        @cr.stubs(:bridges).returns(bridges)
        assert_equal options, @cr.complete_with_default_attributes(attr, 'qemu').deep_symbolize_keys
      end

      it 'new container with attr virtio0 empty' do
        attr = { "type" => "lxc", "node_id" => "pve", "start_after_create" => "0", "pool" => "",
                 "config_attributes" =>
                  {
                    "description" => "", "boot" => "", "onboot" => "0",
                    "agent" => "0", "kvm" => "0", "vga" => "std", "scsihw" => "virtio-scsi-pci",
                    "bios" => "seabios", "cpu_type" => "kvm64", "numa" => "0", "spectre" => "0",
                    "pcid" => "0", "ssbd" => "0", "ibpb" => "0", "virt_ssbd" => "0", "amd_ssbd" => "0",
                    "amd_no_ssb" => "0", "md_clear" => "0", "pdpe1gb" => "0", "hv_tlbflush" => "0", "aes" => "0",
                    "hv_evmcs" => "0", "ostype" => "l26"
                  },
                 "volumes_attributes" =>
                  {
                    "0" =>
                     {
                       "_delete" => "", "storage" => "local-vm", "size" => 8_589_934_592,
                       "storage_type" => "rootfs", "id" => "rootfs", "options" => {}
                     },
                    "1" => { "id" => "virtio0" }
                  },
                 "interfaces_attributes" =>
                  {
                    "0" =>
                    {
                      "id" => "net0",
                      "compute_attributes" =>
                        {
                          "name" => "eth0", "bridge" => "vmbr0", "dhcp" => 1, "dhcp6" => 1
                        }
                    }
                  } }.deep_symbolize_keys
        options = { "name" => "foreman_#{Time.now.to_i}", "vmid" => 100, "node_id" => "pve", "type" => "lxc",
                    "config_attributes" => {
                      "description" => "",
                      "boot" => "",
                      "onboot" => "0", "agent" => "0", "kvm" => "0", "vga" => "std",
                      "scsihw" => "virtio-scsi-pci", "bios" => "seabios", "cpu_type" => "kvm64",
                      "numa" => "0", "spectre" => "0",
                      "pcid" => "0", "ssbd" => "0", "ibpb" => "0", "virt_ssbd" => "0",
                      "amd_ssbd" => "0",
                      "amd_no_ssb" => "0", "md_clear" => "0", "pdpe1gb" => "0", "hv_tlbflush" => "0", "aes" => "0", "hv_evmcs" => "0",
                      "ostype" => "l26"
                    },
                    "volumes_attributes" =>
                    {
                      "0" =>
                      {
                        "_delete" => "", "storage" => "local-vm", "size" => 8_589_934_592, "storage_type" => "rootfs", "id" => "rootfs", "options" => {}
                      },
                      "1" =>
                      {
                        "storage" => "local-vm", "size" => 8_589_934_592, "controller" => "virtio", "device" => "0", "id" => "virtio0", "options" => { "cache" => "none" }
                      }
                    },
                    "interfaces_attributes" => { "0" => { "id" => "net0", "compute_attributes" => { "name" => "eth0", "bridge" => "vmbr0", "dhcp" => 1, "dhcp6" => 1 } } }, "start_after_create" => "0", "pool" => "" }
        node = mock('node')
        servers = mock('servers')
        storages = mock('storages')
        bridges = mock('bridges')
        bridge = mock('bridge')
        bridge.stubs(:identity).returns('vmbr0')
        storage = mock('storage')
        storage.stubs(:first).returns(storage)
        storage.stubs(:identity).returns('local-vm')
        storages.stubs(:first).returns(storage)
        bridges.stubs(:first).returns(bridge)
        servers.stubs(:next_id).returns(100)
        node.stubs(:servers).returns(servers)
        node.stubs(:node).returns('pve')
        nodes = mock('nodes')
        nodes.stubs(:first).returns(node)
        @cr.stubs(:nodes).returns(nodes)
        @cr.stubs(:storages).returns(storages)
        @cr.stubs(:bridges).returns(bridges)
        assert_equal options, @cr.complete_with_default_attributes(attr, 'lxc')
      end
    end
  end
end
