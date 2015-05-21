module ForemanPluginTemplate
  module HostExtensions
    extend ActiveSupport::Concern

    included do
      # execute callbacks
    end

    # create or overwrite instance methods...
    def instance_method_name
    end

    module ClassMethods
      # create or overwrite class methods...
      def class_method_name
      end
    end
  end
end
