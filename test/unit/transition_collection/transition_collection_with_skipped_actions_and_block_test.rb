require_relative '../../test_helper'

class TransitionCollectionWithSkippedActionsAndBlockTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass, initial: :parked, action: :save_state)
    @machine.state :idling
    @machine.event :ignite

    @object = @klass.new

    @transitions = StateMachines::TransitionCollection.new([
      @state_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    ], actions: false)
    @result = @transitions.perform { @ran_block = true; 1 }
  end

  def test_should_succeed
    assert_equal 1, @result
  end

  def test_should_persist_states
    assert_equal 'idling', @object.state
  end

  def test_should_run_block
    assert @ran_block
  end

  def test_should_store_results_in_transitions
    assert_equal 1, @state_transition.result
  end
end
