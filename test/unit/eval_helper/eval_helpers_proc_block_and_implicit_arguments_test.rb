# frozen_string_literal: true

require 'test_helper'

class EvalHelpersProcBlockAndImplicitArgumentsTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    @object = Object.new
    @proc = ->(*args) { args }
  end

  def test_should_call_method_on_object_with_all_arguments_and_block
    block = -> { true }

    assert_equal [@object, 1, 2, 3, block], evaluate_method(@object, @proc, 1, 2, 3, &block)
  end
end
