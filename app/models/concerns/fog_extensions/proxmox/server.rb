module FogExtensions
  module Proxmox
    module Server
      extend ActiveSupport::Concern

      include ActionView::Helpers::NumberHelper

      attr_accessor :start
      attr_accessor :memory_min, :memory_max, :custom_template_name, :builtin_template_name, :hypervisor_host

      def to_s
        name
      end

      def nics_attributes=(attrs)
        config.nics
      end

      def volumes_attributes=(attrs)
        volumes
      end

      def memory
        config.memory
      end

      def mac
        config.mac_addresses.first
      end

      def state
        status
      end

      def vm_description
        format(_('%{cpus} CPUs and %{ram} memory'), :cpus => vcpus_max, :ram => number_to_human_size(memory_max.to_i))
      end

      def interfaces
        config.nics
      end

      def select_nic(fog_nics, nic)
        fog_nics[0]
      end
    end
  end
end
