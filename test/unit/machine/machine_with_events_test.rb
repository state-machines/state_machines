require_relative '../../test_helper'

class MachineWithEventsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
  end

  def test_should_return_the_created_event
    assert_instance_of StateMachines::Event, @machine.event(:ignite)
  end

  def test_should_create_event_with_given_name
    event = @machine.event(:ignite) {}
    assert_equal :ignite, event.name
  end

  def test_should_evaluate_block_within_event_context
    responded = false
    @machine.event :ignite do
      responded = respond_to?(:transition)
    end

    assert responded
  end

  def test_should_be_aliased_as_on
    event = @machine.on(:ignite) {}
    assert_equal :ignite, event.name
  end

  def test_should_have_events
    event = @machine.event(:ignite)
    assert_equal [event], @machine.events.to_a
  end

  def test_should_allow_human_state_name_lookup
    @machine.event(:ignite)
    assert_equal 'ignite', @klass.human_state_event_name(:ignite)
  end

  def test_should_raise_exception_on_invalid_human_state_event_name_lookup
    exception = assert_raises(IndexError) { @klass.human_state_event_name(:invalid) }
    assert_equal ':invalid is an invalid name', exception.message
  end

  def test_should_raise_exception_if_conflicting_type_used_for_name
    @machine.event :park
    exception = assert_raises(ArgumentError) {  @machine.event 'ignite' }
    assert_equal '"ignite" event defined as String, :park defined as Symbol; all events must be consistent', exception.message
  end
end
