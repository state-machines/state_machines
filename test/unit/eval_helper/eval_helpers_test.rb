require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
  end

  def test_should_raise_exception_if_method_is_not_symbol_string_or_proc
    exception = assert_raises(ArgumentError) { evaluate_method(@object, 1) }
    assert_match(/Methods must/, exception.message)
  end
end
