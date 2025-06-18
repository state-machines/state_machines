# frozen_string_literal: true

require 'test_helper'
require 'unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcWithBlockWithoutObjectTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = ->(block) { [block] }
  end

  def test_should_call_proc_with_block_only
    block = -> { true }

    assert_equal [block], evaluate_method(@object, @proc, 1, 2, 3, &block)
  end
end
