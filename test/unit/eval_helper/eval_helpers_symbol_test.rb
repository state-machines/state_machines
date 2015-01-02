require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersSymbolTest < EvalHelpersBaseTest
  def setup
    class << (@object = Object.new)
      def callback
        true
      end
    end
  end

  def test_should_call_method_on_object_with_no_arguments
    assert_equal true, evaluate_method(@object, :callback, 1, 2, 3)
  end
end
