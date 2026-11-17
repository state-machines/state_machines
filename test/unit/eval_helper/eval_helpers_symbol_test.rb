# frozen_string_literal: true

require 'test_helper'

class EvalHelpersSymbolTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    class << (@object = Object.new)
      def callback
        true
      end
    end
  end

  def test_should_call_method_on_object_with_no_arguments
    assert evaluate_method(@object, :callback, 1, 2, 3)
  end
end
