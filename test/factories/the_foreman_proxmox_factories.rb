# frozen_string_literal: true

# Copyright 2018 Tristan Robert

# This file is part of TheForemanProxmox.

# TheForemanProxmox is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# TheForemanProxmox is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with TheForemanProxmox. If not, see <http://www.gnu.org/licenses/>.

FactoryBot.define do
  factory :container_resource, :class => ComputeResource do
    sequence(:name) { |n| "compute_resource#{n}" }

    trait :proxmox do
      provider 'proxmox'
      url 'https://192.168.56.101:8006/api2/json'
      user 'root@pam'
      password 'proxmox01'
    end

    factory :proxmox_cr, :class => TheForemanProxmox::Proxmox, :traits => [:proxmox]
  end
end
