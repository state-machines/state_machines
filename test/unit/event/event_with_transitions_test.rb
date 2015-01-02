require_relative '../../test_helper'

class EventWithTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition(parked: :idling)
    @event.transition(first_gear: :idling)
  end

  def test_should_include_all_transition_states_in_known_states
    assert_equal [:parked, :idling, :first_gear], @event.known_states
  end

  def test_should_include_new_transition_states_after_calling_known_states
    @event.known_states
    @event.transition(stalled: :idling)

    assert_equal [:parked, :idling, :first_gear, :stalled], @event.known_states
  end

  def test_should_clear_known_states_on_reset
    @event.reset
    assert_equal [], @event.known_states
  end

  def test_should_use_pretty_inspect
    assert_match '#<StateMachines::Event name=:ignite transitions=[:parked => :idling, :first_gear => :idling]>', @event.inspect
  end
end

