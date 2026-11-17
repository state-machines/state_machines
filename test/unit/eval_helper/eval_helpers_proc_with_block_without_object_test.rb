# frozen_string_literal: true

require 'test_helper'

class EvalHelpersProcWithBlockWithoutObjectTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    @object = Object.new
    @proc = ->(block) { [block] }
  end

  def test_should_call_proc_with_block_only
    block = -> { true }

    assert_equal [block], evaluate_method(@object, @proc, 1, 2, 3, &block)
  end
end
