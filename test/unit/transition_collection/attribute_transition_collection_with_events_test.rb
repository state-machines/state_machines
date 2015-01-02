require_relative '../../test_helper'

class AttributeTransitionCollectionWithEventsTest < StateMachinesTest
  def setup
    @klass = Class.new

    @state = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @state.state :idling
    @state.event :ignite

    @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save)
    @status.state :second_gear
    @status.event :shift_up

    @object = @klass.new
    @object.state_event = 'ignite'
    @object.status_event = 'shift_up'

    @transitions = StateMachines::AttributeTransitionCollection.new([
      @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
      @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
    ])
    @result = @transitions.perform
  end

  def test_should_succeed
    assert_equal true, @result
  end

  def test_should_persist_states
    assert_equal 'idling', @object.state
    assert_equal 'second_gear', @object.status
  end

  def test_should_clear_events
    assert_nil @object.state_event
    assert_nil @object.status_event
  end

  def test_should_not_write_event_transitions
    assert_nil @object.send(:state_event_transition)
    assert_nil @object.send(:status_event_transition)
  end
end
