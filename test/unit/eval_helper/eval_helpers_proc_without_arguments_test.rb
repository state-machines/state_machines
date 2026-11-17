# frozen_string_literal: true

require 'test_helper'

class EvalHelpersProcWithoutArgumentsTest < StateMachinesTest
  include StateMachines::EvalHelpers

  def setup
    @object = Object.new
    @proc = ->(*args) { args }
    class << @proc
      def arity
        0
      end
    end
  end

  def test_should_call_proc_with_no_arguments
    assert_empty evaluate_method(@object, @proc, 1, 2, 3)
  end
end
