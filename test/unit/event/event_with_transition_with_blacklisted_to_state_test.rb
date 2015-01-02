require_relative '../../test_helper'
class EventWithTransitionWithBlacklistedToStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.state :parked, :idling, :first_gear, :second_gear

    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition(from: :parked, to: StateMachines::BlacklistMatcher.new([:parked, :idling]))

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
    assert_equal 'first_gear', transition.to
    assert_equal :ignite, transition.event
  end

  def test_should_allow_loopback_first_when_possible
    @event.transition(from: :second_gear, to: StateMachines::BlacklistMatcher.new([:parked, :idling]))
    @object.state = 'second_gear'

    transition = @event.transition_for(@object)
    refute_nil transition
    assert_equal 'second_gear', transition.from
    assert_equal 'second_gear', transition.to
    assert_equal :ignite, transition.event
  end

  def test_should_allow_specific_transition_selection_using_to
    transition = @event.transition_for(@object, from: :parked, to: :second_gear)

    refute_nil transition
    assert_equal 'parked', transition.from
    assert_equal 'second_gear', transition.to
    assert_equal :ignite, transition.event
  end

  def test_should_not_allow_transition_selection_if_not_matching
    transition = @event.transition_for(@object, from: :parked, to: :parked)
    assert_nil transition
  end

  def test_should_fire
    assert @event.fire(@object)
  end

  def test_should_change_the_current_state
    @event.fire(@object)
    assert_equal 'first_gear', @object.state
  end
end
