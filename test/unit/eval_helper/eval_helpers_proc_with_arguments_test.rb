# frozen_string_literal: true

require 'test_helper'
require 'unit/eval_helper/eval_helpers_base_test'

class EvalHelpersProcWithArgumentsTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
    @proc = ->(*args) { args }
  end

  def test_should_call_method_with_all_arguments
    assert_equal [@object, 1, 2, 3], evaluate_method(@object, @proc, 1, 2, 3)
  end
end
