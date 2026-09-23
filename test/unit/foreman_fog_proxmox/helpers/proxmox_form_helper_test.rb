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
require 'ostruct'

module ForemanFogProxmox
  class ProxmoxFormHelperTest < ActiveSupport::TestCase
    include ProxmoxFormHelper

    describe 'host interface form attributes' do
      before do
        @compute_resource = mock('compute resource')
        @host = stub(compute_resource: @compute_resource, compute_attributes: {},
          compute_profile_id: nil, hostgroup: nil, uuid: nil)
      end

      %w[qemu lxc].each do |type|
        it "preserves existing #{type} attributes when adding missing defaults" do
          attributes = { 'bridge' => 'vmbr9', 'tag' => '42', 'firewall' => '0' }
          defaults = type == 'qemu' ? { model: 'virtio' } : { name: 'eth0', dhcp: 1, dhcp6: 1 }
          @host.stubs(:compute_attributes).returns(type: type, node_id: 'node-b')
          @compute_resource.expects(:interface_typed_defaults).with(type, bridge: 'vmbr9')
                           .returns(compute_attributes: defaults.merge(bridge: 'vmbr9'))
          @compute_resource.expects(:bridges).never

          result = proxmox_vm_type_and_node_id(@host, OpenStruct.new(compute_attributes: attributes), {})

          assert_equal 'vmbr9', result[:compute_attributes]['bridge']
          assert_equal '42', result[:compute_attributes]['tag']
          assert_equal '0', result[:compute_attributes]['firewall']
          assert_equal({ 'bridge' => 'vmbr9', 'tag' => '42', 'firewall' => '0' }, attributes)
          assert_equal 'node-b', result[:node_id]
        end
      end

      it 'uses the running VM placement and type rather than the old compute profile' do
        @host.stubs(:uuid).returns('1_100')
        @host.expects(:compute_object).once.returns(stub(type: 'lxc', node_id: 'node-b', interfaces: []))
        @host.expects(:compute_profile_id).never
        nic = OpenStruct.new(compute_attributes: { 'name' => 'eth0', 'bridge' => 'vmbr9' })

        2.times do
          result = proxmox_vm_type_and_node_id(@host, nic, {})
          assert_equal 'node-b', result[:node_id]
          assert_equal 'lxc', result[:vm_type]
          assert_equal 'vmbr9', result[:compute_attributes]['bridge']
        end
      end

      %w[qemu lxc].each do |type|
        it "fills missing #{type} NIC attributes from the matching live interface, not the first NIC" do
          @host.stubs(:uuid).returns('1_100')
          mac_key = type == 'qemu' ? :macaddr : :hwaddr
          other = Fog::Proxmox::Compute::Interface.new(:id => 'net0', mac_key => '00:11:22:33:44:55')
          current = Fog::Proxmox::Compute::Interface.new(
            :id => 'net1', mac_key => 'AA:BB:CC:DD:EE:FF', :bridge => 'vmbr9', :model => 'virtio', :name => 'eth0'
          )
          @host.stubs(:compute_object).returns(stub(type: type, node_id: 'node-b', interfaces: [other, current]))
          @compute_resource.expects(:interface_compute_attributes).with(current.attributes)
                           .returns(compute_attributes: current.attributes)
          @compute_resource.expects(:interface_typed_defaults).never
          nic = OpenStruct.new(mac: 'aa:bb:cc:dd:ee:ff', compute_attributes: { 'tag' => '42' })

          result = proxmox_vm_type_and_node_id(@host, nic, {})

          assert_equal 'vmbr9', result[:compute_attributes]['bridge']
          assert_equal '42', result[:compute_attributes]['tag']
        end
      end

      it 'keeps submitted placement and bridge changes ahead of live values' do
        @host.stubs(:uuid).returns('1_100')
        interface = stub(id: 'net0', attributes: { model: 'virtio', bridge: 'vmbr9' })
        @host.stubs(:compute_object).returns(stub(type: 'qemu', node_id: 'node-a', interfaces: [interface]))
        @compute_resource.stubs(:interface_compute_attributes).returns(compute_attributes: interface.attributes)
        nic = OpenStruct.new(compute_attributes: { 'id' => 'net0', 'bridge' => '' })

        params = { host: { compute_attributes: { node_id: 'node-b' },
                           interfaces_attributes: { '0' => { compute_attributes: { bridge: '' } } } } }
        result = proxmox_vm_type_and_node_id(@host, nic, params)

        assert_equal 'node-b', result[:node_id]
        assert_equal '', result[:compute_attributes]['bridge']
      end

      it 'uses the live bridge on initial edit instead of stale stored NIC settings' do
        @host.stubs(:uuid).returns('1_100')
        interface = stub(id: 'net0', attributes: { model: 'virtio', bridge: 'vmbr9' })
        @host.stubs(:compute_object).returns(stub(type: 'qemu', node_id: 'node-b', interfaces: [interface]))
        @compute_resource.stubs(:interface_compute_attributes).returns(compute_attributes: interface.attributes)
        nic = OpenStruct.new(compute_attributes: { 'id' => 'net0', 'model' => 'virtio', 'bridge' => 'vmbr0' })

        result = proxmox_vm_type_and_node_id(@host, nic, {})

        assert_equal 'vmbr9', result[:compute_attributes]['bridge']
        assert_equal 'vmbr0', nic.compute_attributes['bridge']
      end
    end

    describe 'bridge choices' do
      before do
        @compute_resource = mock('compute resource')
        @compute_resource.stubs(:nodes).returns(
          [stub(node: 'node-a'), stub(node: 'node-b')]
        )
      end

      it 'queries only the selected node' do
        @compute_resource.expects(:bridges).with('node-b').returns([stub(iface: 'vmbr0'), stub(iface: 'vmbr9')])

        assert_equal [['vmbr0', 'vmbr0'], ['vmbr9', 'vmbr9']],
          proxmox_bridge_options(@compute_resource, 'node-b', 'vmbr9')
      end

      it 'retains an unlisted bridge without substituting the first bridge' do
        @compute_resource.expects(:bridges).with('node-b').returns([stub(iface: 'vmbr0')])

        assert_equal [['vmbr9 (unavailable)', 'vmbr9'], ['vmbr0', 'vmbr0']],
          proxmox_bridge_options(@compute_resource, 'node-b', 'vmbr9')
      end

      it 'retains the selected bridge on a removed node without querying another node' do
        @compute_resource.expects(:bridges).never

        assert_equal [['vmbr9 (unavailable)', 'vmbr9']],
          proxmox_bridge_options(@compute_resource, 'removed', 'vmbr9')
      end

      it 'defaults to the first node when no node is selected' do
        @compute_resource.expects(:bridges).with('node-a').returns([stub(iface: 'vmbr0')])

        assert_equal [['vmbr0', 'vmbr0']], proxmox_bridge_options(@compute_resource, nil)
      end

      it 'returns no choices when the node inventory is absent' do
        @compute_resource.stubs(:nodes).returns(nil)
        @compute_resource.expects(:bridges).never

        assert_empty proxmox_bridge_options(@compute_resource, nil)
      end
    end

    describe 'rendered NIC bridge fields' do
      %w[qemu lxc].product([true, false]).each do |type, listed|
        it "preserves the submitted #{type} bridge when it is #{listed ? 'listed' : 'unlisted'}" do
          compute_resource = mock('compute resource',
            nodes: [stub(node: 'node-a')])
          bridges = [stub(iface: 'vmbr0')]
          bridges << stub(iface: 'vmbr9') if listed
          compute_resource.expects(:bridges).with('node-a').returns(bridges)
          view = ActionView::Base.with_empty_template_cache.new(
            ActionView::LookupContext.new([File.expand_path('../../../../app/views', __dir__)]), {}, nil
          )
          view.extend(FormHelper)
          view.extend(ProxmoxFormHelper)
          view.define_singleton_method(:field) { |_form, _attribute, _options, &block| block.call }
          view.stubs(:proxmox_networkcards_map).returns([OpenStruct.new(id: 'virtio', name: 'VirtIO')])
          view.stubs(:javascript_include_tag).returns(''.html_safe)
          nic = OpenStruct.new(bridge: 'vmbr9', model: 'virtio', name: 'eth0')
          form = ActionView::Helpers::FormBuilder.new('host[interfaces_attributes][0][compute_attributes]', nic, view, {})
          html = view.render(
            partial: "compute_resources_vms/form/proxmox/#{type == 'qemu' ? 'server' : 'container'}/network",
            locals: { f: form, vm_type: type, node_id: 'node-a', compute_resource: compute_resource }
          )
          select = Nokogiri::HTML.fragment(html).at_css('select[data-proxmox-bridge]')

          assert_equal 'host[interfaces_attributes][0][compute_attributes][bridge]', select['name']
          assert_equal 'vmbr9', select.at_css('option[selected]')['value']
          assert_equal listed ? 'vmbr9' : 'vmbr9 (unavailable)', select.at_css('option[selected]').text
        end
      end
    end

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
