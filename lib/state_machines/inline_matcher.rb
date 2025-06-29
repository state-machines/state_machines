# frozen_string_literal: true

module StateMachines
  # Metaprogramming approach: inline the matcher check directly into classes
  module InlineMatcher
    def self.apply!
      # Define the method directly in each class that needs it
      [NodeCollection, Branch].each do |klass|
        klass.class_eval do
          private

          def matcher?(value)
            value.is_a?(StateMachines::Matcher) ||
              (value.respond_to?(:matches?) && value.respond_to?(:values))
          end
        end
      end

      # For module methods in Machine
      Machine::StateMethods.module_eval do
        private

        def matcher?(value)
          value.is_a?(StateMachines::Matcher) ||
            (value.respond_to?(:matches?) && value.respond_to?(:values))
        end
      end

      Machine::EventMethods.module_eval do
        private

        def matcher?(value)
          value.is_a?(StateMachines::Matcher) ||
            (value.respond_to?(:matches?) && value.respond_to?(:values))
        end
      end
    end
  end
end
