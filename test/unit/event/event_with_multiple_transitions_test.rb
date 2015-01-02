require_relative '../../test_helper'

class EventWithMultipleTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling

    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition(idling: :idling)
    @event.transition(parked: :idling)
    @event.transition(parked: :parked)

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
    assert_equal 'idling', transition.to
    assert_equal :ignite, transition.event
  end

  def test_should_allow_specific_transition_selection_using_from
    transition = @event.transition_for(@object, from: :idling)

    refute_nil transition
    assert_equal 'idling', transition.from
    assert_equal 'idling', transition.to
    assert_equal :ignite, transition.event
  end

  def test_should_allow_specific_transition_selection_using_to
    transition = @event.transition_for(@object, from: :parked, to: :parked)

    refute_nil transition
    assert_equal 'parked', transition.from
    assert_equal 'parked', transition.to
    assert_equal :ignite, transition.event
  end

  def test_should_not_allow_specific_transition_selection_using_on
    exception = assert_raises(ArgumentError) { @event.transition_for(@object, on: :park) }
    assert_equal 'Unknown key: :on. Valid keys are: :from, :to, :guard', exception.message
  end

  def test_should_fire
    assert @event.fire(@object)
  end

  def test_should_change_the_current_state
    @event.fire(@object)
    assert_equal 'idling', @object.state
  end
end
