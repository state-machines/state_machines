require_relative '../../test_helper'

class TransitionCollectionTest < StateMachinesTest
  def test_should_raise_exception_if_invalid_option_specified
    exception = assert_raises(ArgumentError) { StateMachines::TransitionCollection.new([], invalid: true) }
    assert_equal 'Unknown key: :invalid. Valid keys are: :actions, :after, :use_transactions', exception.message
  end

  def test_should_raise_exception_if_multiple_transitions_for_same_attribute_specified
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new

    exception = assert_raises(ArgumentError) do
      StateMachines::TransitionCollection.new([
        StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
        StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
      ])
    end
    assert_equal 'Cannot perform multiple transitions in parallel for the same state machine attribute', exception.message
  end
end
