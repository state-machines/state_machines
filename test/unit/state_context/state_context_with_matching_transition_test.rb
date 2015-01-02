require_relative '../../test_helper'

class StateContextWithMatchingTransitionTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @state = @machine.state :parked

    @state_context = StateMachines::StateContext.new(@state)
    @state_context.transition(to: :idling, on: :ignite)

    @event = @machine.event(:ignite)
    @object = @klass.new
  end

  def test_should_be_able_to_fire
    assert @event.can_fire?(@object)
  end

  def test_should_have_a_transition
    transition = @event.transition_for(@object)
    refute_nil transition
    assert_equal 'parked', transition.from
    assert_equal 'idling', transition.to
    assert_equal :ignite, transition.event
  end
end
