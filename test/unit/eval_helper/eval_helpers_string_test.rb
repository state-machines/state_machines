require_relative '../../test_helper'
require_relative '../../unit/eval_helper/eval_helpers_base_test.rb'

class EvalHelpersStringTest < EvalHelpersBaseTest
  def setup
    @object = Object.new
  end

  def test_should_evaluate_string
    assert_equal 1, evaluate_method(@object, '1')
  end

  def test_should_evaluate_string_within_object_context
    @object.instance_variable_set('@value', 1)
    assert_equal 1, evaluate_method(@object, '@value')
  end

  def test_should_ignore_additional_arguments
    assert_equal 1, evaluate_method(@object, '1', 2, 3, 4)
  end
end




