module StateMachines
  module Integrations
    # Provides a set of base helpers for managing individual integrations
    module Base
      module ClassMethods
        # The default options to use for state machines using this integration
        attr_reader :defaults

        # The name of the integration
        def integration_name
          @integration_name ||= begin
            name = self.name.split('::').last
            name.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            name.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
            name.downcase!
            name.to_sym
          end
        end

        # The list of ancestor names that cause this integration to matched.
        def matching_ancestors
          []
        end

        # Whether the integration should be used for the given class.
        def matches?(klass)
          matching_ancestors.any? { |ancestor| klass <= ancestor }
        end

        # Whether the integration should be used for the given list of ancestors.
        def matches_ancestors?(ancestors)
          (ancestors & matching_ancestors).any?
        end
      end

      def self.included(base) #:nodoc:
        base.extend ClassMethods
      end
    end
  end
end
