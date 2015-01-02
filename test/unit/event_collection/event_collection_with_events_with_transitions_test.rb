require_relative '../../test_helper'

class EventCollectionWithEventsWithTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @events = StateMachines::EventCollection.new(@machine)

    @machine.state :idling, :first_gear

    @events << @ignite = StateMachines::Event.new(@machine, :ignite)
    @ignite.transition parked: :idling

    @events << @park = StateMachines::Event.new(@machine, :park)
    @park.transition idling: :parked

    @events << @shift_up = StateMachines::Event.new(@machine, :shift_up)
    @shift_up.transition parked: :first_gear
    @shift_up.transition idling: :first_gear, if: lambda { false }

    @machine.events.concat(@events)

    @object = @klass.new
  end

  def test_should_find_valid_events_based_on_current_state
    assert_equal [@ignite, @shift_up], @events.valid_for(@object)
  end

  def test_should_filter_valid_events_by_from_state
    assert_equal [@park], @events.valid_for(@object, from: :idling)
  end

  def test_should_filter_valid_events_by_to_state
    assert_equal [@shift_up], @events.valid_for(@object, to: :first_gear)
  end

  def test_should_filter_valid_events_by_event
    assert_equal [@ignite], @events.valid_for(@object, on: :ignite)
  end

  def test_should_filter_valid_events_by_multiple_requirements
    assert_equal [], @events.valid_for(@object, from: :idling, to: :first_gear)
  end

  def test_should_allow_finding_valid_events_without_guards
    assert_equal [@shift_up], @events.valid_for(@object, from: :idling, to: :first_gear, guard: false)
  end

  def test_should_find_valid_transitions_based_on_current_state
    assert_equal [
                     StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                     StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :first_gear)
                 ], @events.transitions_for(@object)
  end

  def test_should_filter_valid_transitions_by_from_state
    assert_equal [StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)], @events.transitions_for(@object, from: :idling)
  end

  def test_should_filter_valid_transitions_by_to_state
    assert_equal [StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :first_gear)], @events.transitions_for(@object, to: :first_gear)
  end

  def test_should_filter_valid_transitions_by_event
    assert_equal [StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)], @events.transitions_for(@object, on: :ignite)
  end

  def test_should_filter_valid_transitions_by_multiple_requirements
    assert_equal [], @events.transitions_for(@object, from: :idling, to: :first_gear)
  end

  def test_should_allow_finding_valid_transitions_without_guards
    assert_equal [StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)], @events.transitions_for(@object, from: :idling, to: :first_gear, guard: false)
  end
end
