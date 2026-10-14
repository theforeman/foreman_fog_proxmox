# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanFogProxmox
  class HostsControllerTest < ActiveSupport::TestCase
    describe 'clone' do
      before do
        controller_class = Class.new do
          attr_accessor :host

          def clone
            @host = host
          end

          include ForemanFogProxmox::HostsController
        end
        @controller = controller_class.new
        @controller.stubs(:next_vmid).returns(101)
        @compute_attributes = {
          vmid: 100,
          interfaces_attributes: {},
          volumes_attributes: {},
          config_attributes: { bios: 'ovmf', is_secure_boot: '1' },
        }.with_indifferent_access
        @controller.host = stub('host',
          compute_resource: FactoryBot.build_stubbed(:proxmox_cr),
          compute_attributes: @compute_attributes)
      end

      it 'resets the EFI disk volume ID in the cloned host compute attributes' do
        @compute_attributes[:config_attributes][:efidisk] = Fog::Proxmox::Compute::Efidisk.new(
          volid: 'local-lvm:vm-100-disk-0',
          storage: 'local-lvm',
          efitype: '4m',
          pre_enrolled_keys: '1'
        )

        @controller.clone

        efidisk = @controller.host.compute_attributes.dig(:config_attributes, :efidisk)
        assert_equal 'local-lvm:0', efidisk.volid
        assert_equal 'local-lvm', efidisk.storage
        assert_equal '4m', efidisk.efitype
        assert_equal '1', efidisk.pre_enrolled_keys
        assert_equal '1', @controller.host.compute_attributes.dig(:config_attributes, :is_secure_boot)
      end

      it 'clones a host without an EFI disk' do
        @controller.clone

        assert_equal 101, @controller.host.compute_attributes[:vmid]
        assert_nil @controller.host.compute_attributes.dig(:config_attributes, :efidisk)
      end
    end
  end
end
