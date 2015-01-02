require_relative '../../test_helper'

class AttributeTransitionCollectionWithCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @state = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @state.state :idling
    @state.event :ignite

    @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save)
    @status.state :second_gear
    @status.event :shift_up

    @object = @klass.new

    @transitions = StateMachines::AttributeTransitionCollection.new([
      @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
      @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
    ])
  end

  def test_should_not_have_events_during_before_callbacks
    @state.before_transition { |object, _transition| @before_state_event = object.state_event }
    @state.around_transition { |object, _transition, block| @around_state_event = object.state_event; block.call }
    @transitions.perform

    assert_nil @before_state_event
    assert_nil @around_state_event
  end

  def test_should_not_have_events_during_action
    @transitions.perform { @state_event = @object.state_event }

    assert_nil @state_event
  end

  def test_should_not_have_events_during_after_callbacks
    @state.after_transition { |object, _transition| @after_state_event = object.state_event }
    @state.around_transition { |object, _transition, block| block.call; @around_state_event = object.state_event }
    @transitions.perform

    assert_nil @after_state_event
    assert_nil @around_state_event
  end

  def test_should_not_have_event_transitions_during_before_callbacks
    @state.before_transition { |object, _transition| @state_event_transition = object.send(:state_event_transition) }
    @transitions.perform

    assert_nil @state_event_transition
  end

  def test_should_not_have_event_transitions_during_action
    @transitions.perform { @state_event_transition = @object.send(:state_event_transition) }

    assert_nil @state_event_transition
  end

  def test_should_not_have_event_transitions_during_after_callbacks
    @state.after_transition { |object, _transition| @after_state_event_transition = object.send(:state_event_transition) }
    @state.around_transition { |object, _transition, block| block.call; @around_state_event_transition = object.send(:state_event_transition) }
    @transitions.perform

    assert_nil @after_state_event_transition
    assert_nil @around_state_event_transition
  end
end
