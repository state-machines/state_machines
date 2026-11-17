# frozen_string_literal: true

require 'test_helper'

class EvalHelpersSymbolMethodMissingTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    class << (@object = Object.new)
      def method_missing(symbol, *)
        send("method_missing_#{symbol}", *)
      end

      def method_missing_callback(*args)
        args
      end
    end
  end

  def test_should_call_dynamic_method_with_all_arguments
    assert_equal [1, 2, 3], evaluate_method(@object, :callback, 1, 2, 3)
  end
end
