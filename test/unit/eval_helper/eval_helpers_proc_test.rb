require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = ->(obj) { obj }
  end

  def test_should_call_proc_with_object_as_argument
    assert_equal @object, evaluate_method(@object, @proc, 1, 2, 3)
  end
end
