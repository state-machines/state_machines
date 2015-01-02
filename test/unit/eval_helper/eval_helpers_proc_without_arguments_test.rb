require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcWithBlockWithoutArgumentsTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = lambda { |*args| args }
    class << @proc
      def arity
        0
      end
    end
  end

  def test_should_call_proc_without_arguments
    block = lambda { true }
    assert_equal [], evaluate_method(@object, @proc, 1, 2, 3, &block)
  end
end
