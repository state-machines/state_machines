# frozen_string_literal: true

require 'test_helper'

class EvalHelpersProcWithArgumentsTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    @object = Object.new
    @proc = ->(*args) { args }
  end

  def test_should_call_method_with_all_arguments
    assert_equal [@object, 1, 2, 3], evaluate_method(@object, @proc, 1, 2, 3)
  end
end
