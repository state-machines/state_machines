require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcWithBlockWithoutObjectTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = lambda { |block| [block] }
  end

  def test_should_call_proc_with_block_only
    block = lambda { true }
    assert_equal [block], evaluate_method(@object, @proc, 1, 2, 3, &block)
  end
end
