require_relative '../../test_helper'

class MachineAfterBeingCopiedTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new, :state, initial: :parked)
    @machine.event(:ignite) {}
    @machine.before_transition(lambda {})
    @machine.after_transition(lambda {})
    @machine.around_transition(lambda {})
    @machine.after_failure(lambda {})

    @copied_machine = @machine.clone
  end

  def test_should_not_have_the_same_collection_of_states
    refute_same @copied_machine.states, @machine.states
  end

  def test_should_copy_each_state
    refute_same @copied_machine.states[:parked], @machine.states[:parked]
  end

  def test_should_update_machine_for_each_state
    assert_equal @copied_machine, @copied_machine.states[:parked].machine
  end

  def test_should_not_update_machine_for_original_state
    assert_equal @machine, @machine.states[:parked].machine
  end

  def test_should_not_have_the_same_collection_of_events
    refute_same @copied_machine.events, @machine.events
  end

  def test_should_copy_each_event
    refute_same @copied_machine.events[:ignite], @machine.events[:ignite]
  end

  def test_should_update_machine_for_each_event
    assert_equal @copied_machine, @copied_machine.events[:ignite].machine
  end

  def test_should_not_update_machine_for_original_event
    assert_equal @machine, @machine.events[:ignite].machine
  end

  def test_should_not_have_the_same_callbacks
    refute_same @copied_machine.callbacks, @machine.callbacks
  end

  def test_should_not_have_the_same_before_callbacks
    refute_same @copied_machine.callbacks[:before], @machine.callbacks[:before]
  end

  def test_should_not_have_the_same_after_callbacks
    refute_same @copied_machine.callbacks[:after], @machine.callbacks[:after]
  end

  def test_should_not_have_the_same_failure_callbacks
    refute_same @copied_machine.callbacks[:failure], @machine.callbacks[:failure]
  end
end
