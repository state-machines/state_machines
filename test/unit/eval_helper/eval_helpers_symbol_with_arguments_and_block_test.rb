require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersSymbolWithArgumentsAndBlockTest < EvalHelpersBaseTest
  def setup
    class << (@object = Object.new)
      def callback(*args)
        args << yield
      end
    end
  end

  def test_should_call_method_on_object_with_all_arguments_and_block
    assert_equal [1, 2, 3, true], evaluate_method(@object, :callback, 1, 2, 3) { true }
  end
end
