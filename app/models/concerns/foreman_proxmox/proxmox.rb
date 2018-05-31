require 'fog/proxmox'

module ForemanProxmox
  class Proxmox < ComputeResource
    attr_accessor :ssl_verify_peer
    validates :url, :user, :password, :ssl_verify_peer, :presence => true

    def provided_attributes
      super.merge(
        :uuid => :reference,
        :mac  => :mac
      )
    end

    def capabilities
      [:build]
    end

    def find_vm_by_uuid(vmid)
      node.servers.get(vmid)
    rescue Fog::Errors::Error => e
      Foreman::Logging.exception("Failed retrieving proxmox vm by vmid #{vmid}", e)
      raise(ActiveRecord::RecordNotFound) if e.message.include?('HANDLE_INVALID')
      raise(ActiveRecord::RecordNotFound) if e.message.include?('VM.get_record: ["SESSION_INVALID"')
      raise e
    end

    # we default to destroy the VM's storage as well.
    def destroy_vm(ref, args = {})
      logger.info "destroy_vm: #{ref} #{args}"
      find_vm_by_uuid(ref).destroy
    rescue ActiveRecord::RecordNotFound
      true
    end

    def self.model_name
      ComputeResource.model_name
    end

    def test_connection(options = {})
      super
      errors[:url].empty? && errors[:user].empty? && errors[:password].empty? && hypervisor
    rescue => e
      begin
        disconnect
      rescue
        nil
      end
      errors[:base] << e.message
    end

    def available_hypervisors
      read_from_cache('available_hypervisors', 'available_hypervisors!')
    end

    def available_hypervisors!
      store_in_cache('available_hypervisors') do
        hosts = client.nodes.all
        hosts.sort_by(&:node)
      end
    end

    def associated_host(vm)
      associate_by('mac', vm.interfaces.map(&:mac).map { |mac| Net::Validations.normalize_mac(mac) })
    end

    def new_vm(attr = {})
      test_connection
      return unless errors.empty?
      opts = vm_instance_defaults.merge(attr.to_hash).symbolize_keys

      %i[networks volumes].each do |collection|
        nested_attrs     = opts.delete("#{collection}_attributes".to_sym)
        opts[collection] = nested_attributes_for(collection, nested_attrs) if nested_attrs
      end
      opts.reject! { |_, v| v.nil? }
      node.servers.new opts
    end

    def create_vm(args = {})
      custom_template_name  = args[:custom_template_name].to_s
      builtin_template_name = args[:builtin_template_name].to_s

      if builtin_template_name != '' && custom_template_name != ''
        logger.info "custom_template_name: #{custom_template_name}"
        logger.info "builtin_template_name: #{builtin_template_name}"
        raise 'you can select at most one template type'
      end
      begin
        logger.info "create_vm(): custom_template_name: #{custom_template_name}"
        logger.info "create_vm(): builtin_template_name: #{builtin_template_name}"
        vm = custom_template_name != '' ? create_vm_from_custom(args) : create_vm_from_builtin(args)
        vm.set_attribute('name_description', 'Provisioned by Foreman')
        vm.set_attribute('VCPUs_max', args[:vcpus_max])
        vm.set_attribute('VCPUs_at_startup', args[:vcpus_max])
        vm.reload
        return vm
      rescue => e
        logger.info e
        logger.info e.backtrace.join("\n")
        return false
      end
    end

    def hypervisor
      node
    end

    protected

    def client
      @client ||= ::Fog::Compute::Proxmox.new(
        pve_url: url,
        pve_username: user,
        pve_password: password,
        ssl_verify_peer: ssl_verify_peer
      )
    end

    def node(id = 'pve') # default cluster node is 'pve'
      client.nodes.find_by_id id
    end

    def disconnect
      client.terminate if @client
      @client = nil
    end

    def vm_instance_defaults
      super.merge({})
    end

    private

    def get_hypervisor_host(args)
      return client.nodes.first unless args[:hypervisor_host] != ''
      client.nodes.find { |host| node.node == args[:hypervisor_host] }
    end

    def read_from_cache(key, fallback)
      value = Rails.cache.fetch(cache_key + key) { public_send(fallback) }
      value
    end

    def store_in_cache(key)
      value = yield
      Rails.cache.write(cache_key + key, value)
      value
    end

    def cache_key
      "computeresource_#{id}/"
    end
  end
end
