require_relative '../../test_helper'

class MachineWithOtherStates < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @parked, @idling = @machine.other_states(:parked, :idling)
  end

  def test_should_include_other_states_in_known_states
    assert_equal [@parked, @idling], @machine.states.to_a
  end

  def test_should_use_default_value
    assert_equal 'idling', @idling.value
  end

  def test_should_not_create_matcher
    assert_nil @idling.matcher
  end
end

