# frozen_string_literal: true

require 'test_plugin_helper'

module ForemanFogProxmox
  class ComputeResourceHostAssociatorTest < ActiveSupport::TestCase
    setup do
      @compute_resource = mock('compute_resource')
      @associator = ::ComputeResourceHostAssociator.new(@compute_resource)
      @vm = stub('vm')
      @other_vm = stub('other_vm')
    end

    test 'associates all available VMs when no list is supplied' do
      @compute_resource.expects(:vms).with(:eager_loading => true).returns([@vm, @other_vm])

      [@vm, @other_vm].each do |vm|
        host = mock('host')
        Host.expects(:for_vm_uuid).with(@compute_resource, vm).returns([])
        @compute_resource.expects(:associated_host).with(vm).returns(host)
        host.expects(:associate!).with(@compute_resource, vm)
      end

      @associator.associate_hosts

      assert_equal 2, @associator.hosts.size
      assert_equal 0, @associator.fail_count
    end

    test 'associates only the supplied VM without fetching all VMs' do
      host = mock('host')
      @compute_resource.expects(:vms).never
      Host.expects(:for_vm_uuid).with(@compute_resource, @vm).returns([])
      @compute_resource.expects(:associated_host).with(@vm).returns(host)
      host.expects(:associate!).with(@compute_resource, @vm)

      @associator.associate_hosts([@vm])

      assert_equal [host], @associator.hosts
      assert_equal 0, @associator.fail_count
    end
  end
end
