require_relative '../../test_helper'

class MachineWithTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
  end

  def test_should_require_on_event
    exception = assert_raises(ArgumentError) { @machine.transition(parked: :idling) }
    assert_equal 'Must specify :on event', exception.message
  end

  def test_should_not_allow_except_on_option
    exception = assert_raises(ArgumentError) { @machine.transition(except_on: :ignite, on: :ignite) }
    assert_equal 'Unknown key: :except_on. Valid keys are: :from, :to, :except_from, :except_to, :if, :unless', exception.message
  end

  def test_should_allow_transitioning_without_a_to_state
    @machine.transition(from: :parked, on: :ignite)
  end

  def test_should_allow_transitioning_without_a_from_state
    @machine.transition(to: :idling, on: :ignite)
  end

  def test_should_allow_except_from_option
    @machine.transition(except_from: :idling, on: :ignite)
  end

  def test_should_allow_except_to_option
    @machine.transition(except_to: :parked, on: :ignite)
  end

  def test_should_allow_implicit_options
    branch = @machine.transition(first_gear: :second_gear, on: :shift_up)
    assert_instance_of StateMachines::Branch, branch

    state_requirements = branch.state_requirements
    assert_equal 1, state_requirements.length

    assert_instance_of StateMachines::WhitelistMatcher, state_requirements[0][:from]
    assert_equal [:first_gear], state_requirements[0][:from].values
    assert_instance_of StateMachines::WhitelistMatcher, state_requirements[0][:to]
    assert_equal [:second_gear], state_requirements[0][:to].values
    assert_instance_of StateMachines::WhitelistMatcher, branch.event_requirement
    assert_equal [:shift_up], branch.event_requirement.values
  end

  def test_should_allow_multiple_implicit_options
    branch = @machine.transition(first_gear: :second_gear, second_gear: :third_gear, on: :shift_up)

    state_requirements = branch.state_requirements
    assert_equal 2, state_requirements.length
  end

  def test_should_allow_verbose_options
    branch = @machine.transition(from: :parked, to: :idling, on: :ignite)
    assert_instance_of StateMachines::Branch, branch
  end

  def test_should_include_all_transition_states_in_machine_states
    @machine.transition(parked: :idling, on: :ignite)

    assert_equal [:parked, :idling], @machine.states.map { |state| state.name }
  end

  def test_should_include_all_transition_events_in_machine_events
    @machine.transition(parked: :idling, on: :ignite)

    assert_equal [:ignite], @machine.events.map { |event| event.name }
  end

  def test_should_allow_multiple_events
    branches = @machine.transition(parked: :ignite, on: [:ignite, :shift_up])

    assert_equal 2, branches.length
    assert_equal [:ignite, :shift_up], @machine.events.map { |event| event.name }
  end

  def test_should_not_modify_options
    options = { parked: :idling, on: :ignite }
    @machine.transition(options)

    assert_equal options, parked: :idling, on: :ignite
  end
end
