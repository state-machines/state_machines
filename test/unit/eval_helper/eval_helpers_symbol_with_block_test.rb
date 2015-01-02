require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersSymbolWithBlockTest < EvalHelpersBaseTest
  def setup
    class << (@object = Object.new)
      def callback
        yield
      end
    end
  end

  def test_should_call_method_on_object_with_block
    assert_equal true, evaluate_method(@object, :callback) { true }
  end
end
