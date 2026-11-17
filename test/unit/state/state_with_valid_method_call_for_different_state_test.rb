# frozen_string_literal: true

require 'test_helper'

class StateWithValidMethodCallForDifferentStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @ancestors = @klass.ancestors
    @machine.states << @state = StateMachines::State.new(@machine, :idling)
    @state.context do
      def speed
        0
      end
    end

    @object = @klass.new
  end

  def test_should_call_method_missing_arg
    assert_equal 1, @state.call(@object, :speed, method_missing: -> { 1 })
  end

  def test_should_raise_invalid_context_without_a_fallback
    exception = assert_raises(StateMachines::InvalidContext) { @state.call(@object, :speed) }

    assert_equal @object, exception.object
    assert_equal 'State nil for :state is not a valid context for calling #speed', exception.message
  end

  def test_should_report_arguments_as_no_method_error_does
    exception = assert_raises(StateMachines::InvalidContext) { @state.call(@object, :speed, args: [1], kwargs: { x: 2 }) }

    assert_equal [1, { x: 2 }], exception.args
  end

  def test_should_let_a_fallback_error_propagate_unchanged
    error = NoMethodError.new('Invalid', :speed, [])
    raised = assert_raises(NoMethodError) { @state.call(@object, :speed, method_missing: -> { raise error }) }

    assert_same error, raised
  end
end
