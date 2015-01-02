require_relative '../../test_helper'

class MachineAfterChangingInitialState < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.initial_state = :idling

    @object = @klass.new
  end

  def test_should_change_the_initial_state
    assert_equal :idling, @machine.initial_state(@object).name
  end

  def test_should_include_in_known_states
    assert_equal [:parked, :idling], @machine.states.map { |state| state.name }
  end

  def test_should_reset_original_initial_state
    refute @machine.state(:parked).initial
  end

  def test_should_set_new_state_to_initial
    assert @machine.state(:idling).initial
  end
end

