# frozen_string_literal: true

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
  class ProxmoxFormHelperTest < ActiveSupport::TestCase
    include ProxmoxFormHelper

    describe 'interface compute attribute validation' do
      let(:required_attrs) do
        {
          'qemu' => { 'model' => 'virtio' },
          'lxc' => { 'name' => 'eth0' },
        }
      end

      it 'rejects attributes when required keys are missing' do
        required_attrs.each_key do |vm_type|
          assert_not send(:proxmox_valid_interface_compute_attributes?, { 'bridge' => 'vmbr0' }, vm_type)
        end
      end

      it 'accepts attributes when required keys are present' do
        required_attrs.each do |vm_type, attrs|
          assert send(:proxmox_valid_interface_compute_attributes?, attrs, vm_type)
        end
      end

      it 'accepts attributes when required keys are present with other keys' do
        required_attrs.each do |vm_type, attrs|
          assert send(:proxmox_valid_interface_compute_attributes?, attrs.merge('bridge' => 'vmbr0'), vm_type)
        end
      end
    end
  end
end
