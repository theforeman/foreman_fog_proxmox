# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanFogProxmox
  class ProxmoxVMConfigHelperTest < ActiveSupport::TestCase
    include ProxmoxVMConfigHelper
    include ProxmoxVMOsTemplateHelper

    describe '#parsed_typed_config RNG attributes' do
      let(:args) do
        {
          'config_attributes' => { 'memory' => '1024' },
          'rng_attributes' => { 'source' => '/dev/urandom', 'max_bytes' => '', 'period' => '' },
        }.with_indifferent_access
      end

      it 'serializes RNG attributes for QEMU and omits blank options' do
        parsed_vm = parsed_typed_config(args, 'qemu')

        assert_equal 'source=/dev/urandom', parsed_vm['rng0']
        assert_equal '1024', parsed_vm['memory']
        assert_not parsed_vm.key?('rng_attributes')
      end

      it 'preserves zero values for RNG rate limiting' do
        args['rng_attributes']['max_bytes'] = '0'
        args['rng_attributes']['period'] = '1000'

        rng = Fog::Proxmox::RngHelper.extract(parsed_typed_config(args, 'qemu')['rng0'])

        assert_equal({ source: '/dev/urandom', max_bytes: '0', period: '1000' }, rng)
      end

      it 'leaves RNG unset for absent or empty attributes' do
        [nil, {}, { 'source' => '', 'max_bytes' => '', 'period' => '' }].each do |rng|
          args['rng_attributes'] = rng

          assert_not parsed_typed_config(args, 'qemu').key?('rng0')
        end
      end

      it 'ignores RNG attributes for containers' do
        assert_not parsed_typed_config(args, 'lxc').key?('rng0')
      end
    end
  end
end
