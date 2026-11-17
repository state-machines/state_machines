# frozen_string_literal: true

require 'test_helper'

class EvalHelpersProcTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    @object = Object.new
    @proc = ->(obj) { obj }
  end

  def test_should_call_proc_with_object_as_argument
    assert_equal @object, evaluate_method(@object, @proc, 1, 2, 3)
  end
end
