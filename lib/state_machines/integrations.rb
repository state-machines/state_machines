module StateMachines
  # Integrations allow state machines to take advantage of features within the
  # context of a particular library.  This is currently most useful with
  # database libraries.  For example, the various database integrations allow
  # state machines to hook into features like:
  # * Saving
  # * Transactions
  # * Observers
  # * Scopes
  # * Callbacks
  # * Validation errors
  # 
  # This type of integration allows the user to work with state machines in a
  # fashion similar to other object models in their application.
  # 
  # The integration interface is loosely defined by various unimplemented
  # methods in the StateMachines::Machine class.  See that class or the various
  # built-in integrations for more information about how to define additional
  # integrations.
  module Integrations
    @integrations = []

    class << self
      #  Register integration
      def register(name_or_module)
        case name_or_module.class.to_s
          when 'Module'
            add(name_or_module)
          else
            fail IntegrationError
        end
        true
      end

      def reset #:nodoc:#
        @integrations = []
      end

      # Gets a list of all of the available integrations for use.
      #
      # == Example
      #
      #   StateMachines::Integrations.integrations
      #   # => []
      #   StateMachines::Integrations.register(StateMachines::Integrations::ActiveModel)
      #   StateMachines::Integrations.integrations
      #   # => [StateMachines::Integrations::ActiveModel]
      def integrations
        # Register all namespaced integrations
        @integrations
      end

      alias_method :list, :integrations

      # Attempts to find an integration that matches the given class.  This will
      # look through all of the built-in integrations under the StateMachines::Integrations
      # namespace and find one that successfully matches the class.
      # 
      # == Examples
      # 
      #   class Vehicle
      #   end
      #   
      #   class ActiveModelVehicle
      #     include ActiveModel::Observing
      #     include ActiveModel::Validations
      #   end
      #   
      #   class ActiveRecordVehicle < ActiveRecord::Base
      #   end
      #   
      #   StateMachines::Integrations.match(Vehicle)             # => nil
      #   StateMachines::Integrations.match(ActiveModelVehicle)  # => StateMachines::Integrations::ActiveModel
      #   StateMachines::Integrations.match(ActiveRecordVehicle) # => StateMachines::Integrations::ActiveRecord
      def match(klass)
        integrations.detect { |integration| integration.matches?(klass) }
      end

      # Attempts to find an integration that matches the given list of ancestors.
      # This will look through all of the built-in integrations under the StateMachines::Integrations
      # namespace and find one that successfully matches one of the ancestors.
      #
      # == Examples
      #
      #   StateMachines::Integrations.match_ancestors([])                    # => nil
      #   StateMachines::Integrations.match_ancestors([ActiveRecord::Base]) # => StateMachines::Integrations::ActiveModel
      def match_ancestors(ancestors)
        integrations.detect { |integration| integration.matches_ancestors?(ancestors) }
      end

      # Finds an integration with the given name.  If the integration cannot be
      # found, then a NameError exception will be raised.
      #
      # == Examples
      #
      #   StateMachines::Integrations.find_by_name(:active_model)  # => StateMachines::Integrations::ActiveModel
      #   StateMachines::Integrations.find_by_name(:active_record) # => StateMachines::Integrations::ActiveRecord
      #   StateMachines::Integrations.find_by_name(:invalid)       # => StateMachines::IntegrationNotFound: :invalid is an invalid integration
      def find_by_name(name)
        integrations.detect { |integration| integration.integration_name == name } || raise(IntegrationNotFound.new(name))
      end

      private

      def add(integration)
        if integration.respond_to?(:integration_name)
          @integrations.insert(0, integration) unless @integrations.include?(integration)
        end
      end
    end
  end
end
