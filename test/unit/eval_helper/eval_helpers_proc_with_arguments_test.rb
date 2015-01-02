require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcWithArgumentsTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = lambda { |*args| args }
  end

  def test_should_call_method_with_all_arguments
    assert_equal [@object, 1, 2, 3], evaluate_method(@object, @proc, 1, 2, 3)
  end
end