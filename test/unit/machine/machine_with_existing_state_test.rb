require_relative '../../test_helper'

class MachineWithExistingStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @state = @machine.state :parked
    @same_state = @machine.state :parked, value: 1
  end

  def test_should_not_create_a_new_state
    assert_same @state, @same_state
  end

  def test_should_update_attributes
    assert_equal 1, @state.value
  end

  def test_should_no_longer_be_able_to_look_up_state_by_original_value
    assert_nil @machine.states['parked', :value]
  end

  def test_should_be_able_to_look_up_state_by_new_value
    assert_equal @state, @machine.states[1, :value]
  end
end

