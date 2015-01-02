require_relative '../../test_helper'

class MachineWithStateMatchersTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
  end

  def test_should_empty_array_for_all_matcher
    assert_equal [], @machine.state(StateMachines::AllMatcher.instance)
  end

  def test_should_return_referenced_states_for_blacklist_matcher
    assert_instance_of StateMachines::State, @machine.state(StateMachines::BlacklistMatcher.new([:parked]))
  end

  def test_should_not_allow_configurations
    exception = assert_raises(ArgumentError) { @machine.state(StateMachines::BlacklistMatcher.new([:parked]), human_name: 'Parked') }
    assert_equal 'Cannot configure states when using matchers (using {:human_name=>"Parked"})', exception.message
  end

  def test_should_track_referenced_states
    @machine.state(StateMachines::BlacklistMatcher.new([:parked]))
    assert_equal [nil, :parked], @machine.states.map { |state| state.name }
  end

  def test_should_eval_context_for_matching_states
    contexts_run = []
    @machine.event(StateMachines::BlacklistMatcher.new([:parked])) { contexts_run << name }

    @machine.event :parked
    assert_equal [], contexts_run

    @machine.event :idling
    assert_equal [:idling], contexts_run

    @machine.event :first_gear, :second_gear
    assert_equal [:idling, :first_gear, :second_gear], contexts_run
  end
end

