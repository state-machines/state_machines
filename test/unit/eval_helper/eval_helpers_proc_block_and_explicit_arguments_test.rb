# frozen_string_literal: true

require 'test_helper'
require 'unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcBlockAndExplicitArgumentsTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = lambda { |object, arg1, arg2, arg3, block| [object, arg1, arg2, arg3, block] }
  end

  def test_should_call_method_on_object_with_all_arguments_and_block
    block = lambda { true }
    assert_equal [@object, 1, 2, 3, block], evaluate_method(@object, @proc, 1, 2, 3, &block)
  end
end
