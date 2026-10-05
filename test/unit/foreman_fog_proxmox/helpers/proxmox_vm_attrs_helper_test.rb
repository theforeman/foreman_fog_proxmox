# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanFogProxmox
  class ProxmoxVMAttrsHelperTest < ActiveSupport::TestCase
    include ProxmoxVMAttrsHelper

    describe '#agent_attrs' do
      let(:param_scope) { 'host[compute_attributes]' }

      [nil, '', '0', 0].each do |agent|
        it "displays a disabled agent with default options when agent is #{agent.inspect}" do
          config = mock('config', agent: agent)

          assert_agent_attrs agent_attrs(param_scope, config), '0', '1', '0', 'virtio'
        end
      end

      ['1', 1, 'enabled=1'].each do |agent|
        it "displays an enabled agent with default options when agent is #{agent.inspect}" do
          config = mock('config', agent: agent)

          assert_agent_attrs agent_attrs(param_scope, config), '1', '1', '0', 'virtio'
        end
      end

      it 'displays explicit agent options' do
        config = mock('config', agent: 'enabled=1,freeze-fs=0,fstrim_cloned_disks=1,type=isa')

        assert_agent_attrs agent_attrs(param_scope, config), '1', '0', '1', 'isa'
      end

      it 'preserves explicit options when the agent is disabled' do
        config = mock('config', agent: 'enabled=0,freeze-fs=0,fstrim_cloned_disks=1,type=isa')

        assert_agent_attrs agent_attrs(param_scope, config), '0', '0', '1', 'isa'
      end

      it 'reads the legacy freeze-fs-on-backup option' do
        config = mock('config', agent: '1,freeze-fs-on-backup=0')

        assert_agent_attrs agent_attrs(param_scope, config), '1', '0', '0', 'virtio'
      end

      it 'prefers freeze-fs over the legacy freeze-fs-on-backup option' do
        config = mock('config', agent: '1,freeze-fs=0,freeze-fs-on-backup=1')

        assert_agent_attrs agent_attrs(param_scope, config), '1', '0', '0', 'virtio'
      end
    end

    describe '#hotplug_attrs' do
      let(:param_scope) { 'host[compute_attributes]' }

      it 'displays only disk and network as selected when both devices are enabled' do
        config = mock('config', hotplug: 'disk,network')

        assert_hotplug_attrs hotplug_attrs(param_scope, config), '1', %w[disk network]
      end

      [nil, '', '1'].each do |hotplug|
        it "displays the default devices when hotplug is #{hotplug.inspect}" do
          config = mock('config', hotplug: hotplug)

          assert_hotplug_attrs hotplug_attrs(param_scope, config), '1', %w[disk network usb]
        end
      end

      ['0', 0].each do |hotplug|
        it "displays hotplug as disabled with no selected devices when hotplug is #{hotplug.inspect}" do
          config = mock('config', hotplug: hotplug)

          assert_hotplug_attrs hotplug_attrs(param_scope, config), '0', []
        end
      end
    end

    private

    def assert_agent_attrs(attrs, enabled, freeze_fs, fstrim, type)
      assert_equal({
        'agent' => { name: "#{param_scope}[config_attributes][agent]", value: enabled },
        'agentFreezeFs' => { name: "#{param_scope}[config_attributes][agent_freeze_fs]", value: freeze_fs },
        'agentFstrimClonedDisks' => { name: "#{param_scope}[config_attributes][agent_fstrim_cloned_disks]", value: fstrim },
        'agentType' => { name: "#{param_scope}[config_attributes][agent_type]", value: type },
      }, attrs)
    end

    def assert_hotplug_attrs(attrs, enabled, devices)
      expected = {
        'hotplug' => { name: "#{param_scope}[config_attributes][hotplug]", value: enabled },
      }
      HOTPLUG_DEVICES.each do |device|
        expected["hotplug#{device.capitalize}"] = {
          name: "#{param_scope}[config_attributes][hotplug_#{device}]",
          value: devices.include?(device) ? '1' : '0',
        }
      end

      assert_equal expected, attrs
    end
  end
end
