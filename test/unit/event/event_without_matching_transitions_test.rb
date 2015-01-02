require_relative '../../test_helper'

class EventWithoutMatchingTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling

    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition(parked: :idling)

    @object = @klass.new
    @object.state = 'idling'
  end

  def test_should_not_be_able_to_fire
    refute @event.can_fire?(@object)
  end

  def test_should_be_able_to_fire_with_custom_from_state
    assert @event.can_fire?(@object, from: :parked)
  end

  def test_should_not_have_a_transition
    assert_nil @event.transition_for(@object)
  end

  def test_should_have_a_transition_with_custom_from_state
    refute_nil @event.transition_for(@object, from: :parked)
  end

  def test_should_not_fire
    refute @event.fire(@object)
  end

  def test_should_not_change_the_current_state
    @event.fire(@object)
    assert_equal 'idling', @object.state
  end
end

