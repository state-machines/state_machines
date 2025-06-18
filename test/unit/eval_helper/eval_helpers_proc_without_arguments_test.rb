# frozen_string_literal: true

require 'test_helper'
require 'unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcWithBlockWithoutArgumentsTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = ->(*args) { args }
    class << @proc
      def arity
        0
      end
    end
  end

  def test_should_call_proc_without_arguments
    block = -> { true }

    assert_empty evaluate_method(@object, @proc, 1, 2, 3, &block)
  end
end
