require_relative '../../test_helper'

class TransitionWithInvalidNodesTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_raise_exception_without_event
    assert_raises(IndexError) { StateMachines::Transition.new(@object, @machine, nil, :parked, :idling) }
  end

  def test_should_raise_exception_with_invalid_event
    assert_raises(IndexError) { StateMachines::Transition.new(@object, @machine, :invalid, :parked, :idling) }
  end

  def test_should_raise_exception_with_invalid_from_state
    assert_raises(IndexError) { StateMachines::Transition.new(@object, @machine, :ignite, :invalid, :idling) }
  end

  def test_should_raise_exception_with_invalid_to_state
    assert_raises(IndexError) { StateMachines::Transition.new(@object, @machine, :ignite, :parked, :invalid) }
  end
end
