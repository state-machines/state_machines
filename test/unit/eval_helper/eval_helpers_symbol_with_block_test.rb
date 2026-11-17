# frozen_string_literal: true

require 'test_helper'

class EvalHelpersSymbolWithBlockTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    class << (@object = Object.new)
      def callback
        yield
      end
    end
  end

  def test_should_call_method_on_object_with_block
    assert evaluate_method(@object, :callback) { true }
  end
end
