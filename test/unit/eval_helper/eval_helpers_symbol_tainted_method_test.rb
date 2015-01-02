require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test'

class EvalHelpersSymbolTaintedMethodTest < EvalHelpersBaseTest
  def setup
    class << (@object = Object.new)
      def callback
        true
      end

      taint
    end
  end

  def test_should_not_raise_security_error
    evaluate_method(@object, :callback, 1, 2, 3)
  end
end
