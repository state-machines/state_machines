require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersSymbolMethodMissingTest < EvalHelpersBaseTest
  def setup
    class << (@object = Object.new)
      def method_missing(symbol, *args)
        send("method_missing_#{symbol}", *args)
      end

      def method_missing_callback(*args)
        args
      end
    end
  end

  def test_should_call_dynamic_method_with_all_arguments
    assert_equal [1, 2, 3], evaluate_method(@object, :callback, 1, 2, 3)
  end
end