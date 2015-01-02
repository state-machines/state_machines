require_relative '../../test_helper'

class EventTransitionsTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
  end

  def test_should_not_raise_exception_if_implicit_option_specified
    @event.transition(invalid: :valid)
  end

  def test_should_not_allow_on_option
    exception = assert_raises(ArgumentError) { @event.transition(on: :ignite) }
    assert_equal 'Unknown key: :on. Valid keys are: :from, :to, :except_from, :except_to, :if, :unless', exception.message
  end

  def test_should_automatically_set_on_option
    branch = @event.transition(to: :idling)
    assert_instance_of StateMachines::WhitelistMatcher, branch.event_requirement
    assert_equal [:ignite], branch.event_requirement.values
  end

  def test_should_not_allow_except_on_option
    exception = assert_raises(ArgumentError) { @event.transition(except_on: :ignite) }
    assert_equal 'Unknown key: :except_on. Valid keys are: :from, :to, :except_from, :except_to, :if, :unless', exception.message
  end

  def test_should_allow_transitioning_without_a_to_state
    @event.transition(from: :parked)
  end

  def test_should_allow_transitioning_without_a_from_state
    @event.transition(to: :idling)
  end

  def test_should_allow_except_from_option
    @event.transition(except_from: :idling)
  end

  def test_should_allow_except_to_option
    @event.transition(except_to: :idling)
  end

  def test_should_allow_transitioning_from_a_single_state
    assert @event.transition(parked: :idling)
  end

  def test_should_allow_transitioning_from_multiple_states
    assert @event.transition([:parked, :idling] => :idling)
  end

  def test_should_allow_transitions_to_multiple_states
    assert @event.transition(parked: [:parked, :idling])
  end

  def test_should_have_transitions
    branch = @event.transition(to: :idling)
    assert_equal [branch], @event.branches
  end
end

