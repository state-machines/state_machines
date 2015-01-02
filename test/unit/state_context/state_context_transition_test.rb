require_relative '../../test_helper'

class StateContextTransitionTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @state = @machine.state :parked

    @state_context = StateMachines::StateContext.new(@state)
  end

  def test_should_not_allow_except_to
    exception = assert_raises(ArgumentError) { @state_context.transition(except_to: :idling) }
    assert_equal 'Unknown key: :except_to. Valid keys are: :from, :to, :on, :if, :unless', exception.message
  end

  def test_should_not_allow_except_from
    exception = assert_raises(ArgumentError) { @state_context.transition(except_from: :idling) }
    assert_equal 'Unknown key: :except_from. Valid keys are: :from, :to, :on, :if, :unless', exception.message
  end

  def test_should_not_allow_implicit_transitions
    exception = assert_raises(ArgumentError) { @state_context.transition(parked: :idling) }
    assert_equal 'Unknown key: :parked. Valid keys are: :from, :to, :on, :if, :unless', exception.message
  end

  def test_should_not_allow_except_on
    exception = assert_raises(ArgumentError) { @state_context.transition(except_on: :park) }
    assert_equal 'Unknown key: :except_on. Valid keys are: :from, :to, :on, :if, :unless', exception.message
  end

  def test_should_require_on_event
    exception = assert_raises(ArgumentError) { @state_context.transition(to: :idling) }
    assert_equal 'Must specify :on event', exception.message
  end

  def test_should_not_allow_missing_from_and_to
    exception = assert_raises(ArgumentError) { @state_context.transition(on: :ignite) }
    assert_equal 'Must specify either :to or :from state', exception.message
  end

  def test_should_not_allow_from_and_to
    exception = assert_raises(ArgumentError) { @state_context.transition(on: :ignite, from: :parked, to: :idling) }
    assert_equal 'Must specify either :to or :from state', exception.message
  end

  def test_should_allow_to_state_if_missing_from_state
    @state_context.transition(on: :park, from: :parked)
  end

  def test_should_allow_from_state_if_missing_to_state
    @state_context.transition(on: :ignite, to: :idling)
  end

  def test_should_automatically_set_to_option_with_from_state
    branch = @state_context.transition(from: :idling, on: :park)
    assert_instance_of StateMachines::Branch, branch

    state_requirements = branch.state_requirements
    assert_equal 1, state_requirements.length

    from_requirement = state_requirements[0][:to]
    assert_instance_of StateMachines::WhitelistMatcher, from_requirement
    assert_equal [:parked], from_requirement.values
  end

  def test_should_automatically_set_from_option_with_to_state
    branch = @state_context.transition(to: :idling, on: :ignite)
    assert_instance_of StateMachines::Branch, branch

    state_requirements = branch.state_requirements
    assert_equal 1, state_requirements.length

    from_requirement = state_requirements[0][:from]
    assert_instance_of StateMachines::WhitelistMatcher, from_requirement
    assert_equal [:parked], from_requirement.values
  end

  def test_should_allow_if_condition
    @state_context.transition(to: :idling, on: :park, if: :seatbelt_on?)
  end

  def test_should_allow_unless_condition
    @state_context.transition(to: :idling, on: :park, unless: :seatbelt_off?)
  end

  def test_should_include_all_transition_states_in_machine_states
    @state_context.transition(to: :idling, on: :ignite)

    assert_equal [:parked, :idling], @machine.states.map { |state| state.name }
  end

  def test_should_include_all_transition_events_in_machine_events
    @state_context.transition(to: :idling, on: :ignite)

    assert_equal [:ignite], @machine.events.map { |event| event.name }
  end

  def test_should_allow_multiple_events
    @state_context.transition(to: :idling, on: [:ignite, :shift_up])

    assert_equal [:ignite, :shift_up], @machine.events.map { |event| event.name }
  end
end
