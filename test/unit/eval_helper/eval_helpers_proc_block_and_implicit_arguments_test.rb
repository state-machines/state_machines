require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcBlockAndImplicitArgumentsTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = lambda { |*args| args }
  end

  def test_should_call_method_on_object_with_all_arguments_and_block
    block = lambda { true }
    assert_equal [@object, 1, 2, 3, block], evaluate_method(@object, @proc, 1, 2, 3, &block)
  end
end
