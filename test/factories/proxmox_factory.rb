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

require 'fog/compute/proxmox/models/node'

FactoryBot.define do
  
  factory :proxmox_resource, :class => ComputeResource do
    sequence(:name) { |n| "compute_resource#{n}" }

    trait :proxmox do
      provider 'Proxmox'
      user 'root@pam'
      password 'proxmox01'
      url 'https://192.168.56.101:8006/api2/json'
      node_id 'pve'
    end

    factory :proxmox_cr, :class => ForemanFogProxmox::Proxmox, :traits => [:proxmox]

  end

  factory :node, :class => Fog::Proxmox::Compute::Node do
    sequence(:identity) { |n| "node#{n}" }
    trait :pve do
      identity 'pve'
    end
    trait :service do
      service :proxmox_cr
    end
    factory :pve_node, :class => Fog::Proxmox::Compute::Node, :traits => [:pve, :service]
  end

  def deferred_nic_attrs
    [:ip, :ip6, :mac, :subnet, :domain]
  end
  
  def set_nic_attributes(host, attributes, evaluator)
    attributes.each do |nic_attribute|
      next unless evaluator.send(nic_attribute).present?
      host.primary_interface.send(:"#{nic_attribute}=", evaluator.send(nic_attribute))
    end
    host
  end

  factory :nic_base_empty, :class => Nic::Base do
    type 'Nic::Base'
  end

  factory :nic_managed_empty, :class => Nic::Managed, :parent => :nic_base_empty do
    type 'Nic::Managed'
    identifier 'net0'  
  end

  factory :host_empty, :class => Host do
    sequence(:name) { |n| "host#{n}" }
    sequence(:hostname) { |n| "host#{n}" }
    trait :compute_attributes do
      { 'type' => 'qemu' }
    end
    compute_attributes { { 'type' => 'qemu' } }
  end

end
