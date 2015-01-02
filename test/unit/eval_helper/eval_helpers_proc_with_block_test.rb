require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcWithBlockTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = lambda { |_obj, block| block.call }
  end

  def test_should_call_method_on_object_with_block
    assert_equal true, evaluate_method(@object, @proc, 1, 2, 3) { true }
  end
end
