require_relative '../../test_helper'

class EventWithInvalidCurrentStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling

    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition(parked: :idling)

    @object = @klass.new
    @object.state = 'invalid'
  end

  def test_should_raise_exception_when_checking_availability
    exception = assert_raises(ArgumentError) { @event.can_fire?(@object) }
    assert_equal '"invalid" is not a known state value', exception.message
  end

  def test_should_raise_exception_when_finding_transition
    exception = assert_raises(ArgumentError) { @event.transition_for(@object) }
    assert_equal '"invalid" is not a known state value', exception.message
  end

  def test_should_raise_exception_when_firing
    exception = assert_raises(ArgumentError) { @event.fire(@object) }
    assert_equal '"invalid" is not a known state value', exception.message
  end
end
