# frozen_string_literal: true

require 'test_helper'

class EvalHelpersStringWithBlockTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    @object = Object.new
  end

  def test_should_call_method_on_object_with_block
    assert_equal 1, evaluate_method(@object, 'yield') { 1 }
  end
end
