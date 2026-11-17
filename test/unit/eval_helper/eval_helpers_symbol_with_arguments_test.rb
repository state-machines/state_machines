# frozen_string_literal: true

require 'test_helper'

class EvalHelpersSymbolWithArgumentsTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    class << (@object = Object.new)
      def callback(*args)
        args
      end
    end
  end

  def test_should_call_method_with_all_arguments
    assert_equal [1, 2, 3], evaluate_method(@object, :callback, 1, 2, 3)
  end
end
