# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanFogProxmox
  class ProxmoxOrchestrationComputeTest < ActiveSupport::TestCase
    class ComputeValueHost
      include Orchestration::Proxmox::Compute

      attr_accessor :compute_resource, :vm
    end

    test '#computeValue prefixes raw vmid for uuid' do
      host = host_with_vm_value('113')

      assert_equal '4_113', host.computeValue(:uuid, :foreman_uuid)
    end

    test '#computeValue does not prefix existing proxmox uuid' do
      host = host_with_vm_value('4_113')

      assert_equal '4_113', host.computeValue(:uuid, :foreman_uuid)
    end

    private

    def host_with_vm_value(value)
      host = ComputeValueHost.new
      host.compute_resource = OpenStruct.new(id: 4)
      host.vm = OpenStruct.new(foreman_uuid: value)
      host
    end
  end
end
