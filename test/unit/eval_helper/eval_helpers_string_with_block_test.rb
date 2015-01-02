require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersStringWithBlockTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
  end

  def test_should_call_method_on_object_with_block
    assert_equal 1, evaluate_method(@object, 'yield') { 1 }
  end
end
