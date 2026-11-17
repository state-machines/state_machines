# frozen_string_literal: true

require 'test_helper'

class EvalHelpersProcWithBlockTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    @object = Object.new
    @proc = ->(_obj, block) { block.call }
  end

  def test_should_call_method_on_object_with_block
    assert evaluate_method(@object, @proc, 1, 2, 3) { true }
  end
end
