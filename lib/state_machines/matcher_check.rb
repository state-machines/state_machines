# frozen_string_literal: true

module StateMachines
  # Separate module for matcher checking using module_function
  module MatcherCheck
    module_function

    def matcher?(value)
      value.is_a?(Matcher) ||
        (value.respond_to?(:matches?) && value.respond_to?(:values))
    end
  end
end
