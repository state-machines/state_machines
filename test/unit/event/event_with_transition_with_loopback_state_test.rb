require_relative '../../test_helper'

class EventWithTransitionWithLoopbackStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked

    @machine.events << @event = StateMachines::Event.new(@machine, :park)
    @event.transition(from: :parked, to: StateMachines::LoopbackMatcher.instance)

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_be_able_to_fire
    assert @event.can_fire?(@object)
  end

  def test_should_have_a_transition
    transition = @event.transition_for(@object)
    refute_nil transition
    assert_equal 'parked', transition.from
    assert_equal 'parked', transition.to
    assert_equal :park, transition.event
  end

  def test_should_fire
    assert @event.fire(@object)
  end

  def test_should_not_change_the_current_state
    @event.fire(@object)
    assert_equal 'parked', @object.state
  end
end
