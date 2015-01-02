require_relative '../../test_helper'

class MachineWithEventsWithTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @event = @machine.event(:ignite) do
      transition parked: :idling
      transition stalled: :idling
    end
  end

  def test_should_have_events
    assert_equal [@event], @machine.events.to_a
  end

  def test_should_track_states_defined_in_event_transitions
    assert_equal [:parked, :idling, :stalled], @machine.states.map { |state| state.name }
  end

  def test_should_not_duplicate_states_defined_in_multiple_event_transitions
    @machine.event :park do
      transition idling: :parked
    end

    assert_equal [:parked, :idling, :stalled], @machine.states.map { |state| state.name }
  end

  def test_should_track_state_from_new_events
    @machine.event :shift_up do
      transition idling: :first_gear
    end

    assert_equal [:parked, :idling, :stalled, :first_gear], @machine.states.map { |state| state.name }
  end
end

