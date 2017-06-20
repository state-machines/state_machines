require_relative '../../test_helper'

class EventWithTransitionWithNilToStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state nil, :idling

    @machine.events << @event = StateMachines::Event.new(@machine, :park)
    @event.transition(idling: nil)

    @object = @klass.new
    @object.state = 'idling'
  end

  def test_should_be_able_to_fire
    assert @event.can_fire?(@object)
  end

  def test_should_have_a_transition
    transition = @event.transition_for(@object)
    refute_nil transition
    assert_equal 'idling', transition.from
    assert_nil transition.to
    assert_equal :park, transition.event
  end

  def test_should_fire
    assert @event.fire(@object)
  end

  def test_should_not_change_the_current_state
    @event.fire(@object)
    assert_nil @object.state
  end
end
