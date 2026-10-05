# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanFogProxmox
  class ProxmoxVMConfigHelperTest < ActiveSupport::TestCase
    include ProxmoxVMConfigHelper

    describe '#parse_agent' do
      let(:config) do
        {
          'agent' => '1',
          'agent_freeze_fs' => '0',
          'agent_fstrim_cloned_disks' => '1',
          'agent_type' => 'isa',
          'memory' => '1024',
        }
      end

      it 'serializes selected agent options and removes the form fields' do
        assert_equal({
          'agent' => 'enabled=1,freeze-fs-on-backup=0,fstrim_cloned_disks=1,type=isa',
          'memory' => '1024',
        }, parse_agent(config))
      end

      it 'serializes a disabled agent while preserving selected options' do
        config['agent'] = '0'

        assert_equal({
          'agent' => 'enabled=0,freeze-fs-on-backup=0,fstrim_cloned_disks=1,type=isa',
          'memory' => '1024',
        }, parse_agent(config))
      end

      [nil, ''].each do |type|
        it "defaults the agent type to virtio when it is #{type.inspect}" do
          config['agent_type'] = type

          assert_equal({
            'agent' => 'enabled=1,freeze-fs-on-backup=0,fstrim_cloned_disks=1,type=virtio',
            'memory' => '1024',
          }, parse_agent(config))
        end
      end

      it 'serializes boolean checkbox values' do
        config['agent'] = true
        config['agent_freeze_fs'] = true
        config['agent_fstrim_cloned_disks'] = false

        assert_equal({
          'agent' => 'enabled=1,freeze-fs-on-backup=1,fstrim_cloned_disks=0,type=isa',
          'memory' => '1024',
        }, parse_agent(config))
      end

      it 'preserves an existing agent configuration when no form fields are submitted' do
        config = { 'agent' => 'enabled=1,freeze-fs=0,fstrim_cloned_disks=1,type=isa', 'memory' => '1024' }

        assert_equal config, parse_agent(config)
      end

      it 'preserves a legacy agent configuration when no form fields are submitted' do
        config = { 'agent' => 'enabled=1,freeze-fs-on-backup=0', 'memory' => '1024' }

        assert_equal config, parse_agent(config)
      end

      it 'leaves the agent unset when no agent fields are submitted' do
        config = { 'memory' => '1024' }

        assert_equal config, parse_agent(config)
      end
    end

    describe '#parse_hotplug' do
      let(:config) do
        {
          'hotplug' => '1',
          'hotplug_disk' => '1',
          'hotplug_network' => '1',
          'hotplug_usb' => '0',
          'hotplug_cpu' => '0',
          'hotplug_memory' => '0',
          'memory' => '1024',
        }
      end

      it 'serializes two selected devices as disk,network and removes the form fields' do
        assert_equal({ 'hotplug' => 'disk,network', 'memory' => '1024' }, parse_hotplug(config))
      end

      it 'serializes disabled hotplug as 0 even when devices are selected' do
        config['hotplug'] = '0'

        assert_equal({ 'hotplug' => '0', 'memory' => '1024' }, parse_hotplug(config))
      end
    end
  end
end
