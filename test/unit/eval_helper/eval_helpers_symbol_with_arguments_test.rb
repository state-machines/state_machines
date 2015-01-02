require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersSymbolWithArgumentsTest < EvalHelpersBaseTest
  def setup
    class << (@object = Object.new)
      def callback(*args)
        args
      end
    end
  end

  def test_should_call_method_with_all_arguments
    assert_equal [1, 2, 3], evaluate_method(@object, :callback, 1, 2, 3)
  end
end
