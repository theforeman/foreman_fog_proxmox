module ForemanProxmox
  module Controller
    module Parameters
      module ComputeResource
        extend ActiveSupport::Concern

        class_methods do
          def compute_resource_params_filter
            super.tap do |filter|   
              filter.permit :ssl_verify_peer,
                :ssl_certs, :disable_proxy
            end
          end

          def compute_resource_params
            self.class.compute_resource_params_filter.filter_params(params, parameter_filter_context)
          end
        end
      end
    end
  end
end
