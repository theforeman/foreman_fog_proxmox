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
  class ProxmoxOrchestrationComputeTest < ActiveSupport::TestCase
    describe 'unmanaged host with Proxmox compute resource' do
      let(:cr) { FactoryBot.build_stubbed(:proxmox_cr) }
      let(:host) do
        FactoryBot.build(:host_empty,
          :managed => false,
          :compute_resource => cr,
          :compute_attributes => { 'type' => 'qemu' })
      end

      test 'setComputeUpdate skips orchestration for unmanaged host' do
        assert host.setComputeUpdate
      end

      test 'setComputeUpdate logs info when skipping for unmanaged host' do
        mock_logger = mock('logger')
        mock_logger.expects(:info).with(format("Skipping Proxmox compute update for %s - host is not managed", host.name))
        host.stubs(:logger).returns(mock_logger)
        host.setComputeUpdate
      end

      test 'delComputeUpdate skips orchestration for unmanaged host' do
        assert host.delComputeUpdate
      end

      test 'delComputeUpdate logs info when skipping for unmanaged host' do
        mock_logger = mock('logger')
        mock_logger.expects(:info).with(format("Skipping Proxmox compute update rollback for %s - host is not managed", host.name))
        host.stubs(:logger).returns(mock_logger)
        host.delComputeUpdate
      end

      test 'setComputeDetails skips orchestration for unmanaged host' do
        assert host.setComputeDetails
      end

      test 'setComputeDetails logs info when skipping for unmanaged host' do
        mock_logger = mock('logger')
        mock_logger.expects(:info).with(format("Skipping Proxmox compute details for %s - host is not managed", host.name))
        host.stubs(:logger).returns(mock_logger)
        host.setComputeDetails
      end
    end
  end
end
