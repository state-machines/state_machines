require_relative '../../test_helper'

class MachineWithStatesWithCustomValuesTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @state = @machine.state :parked, value: 1

    @object = @klass.new
    @object.state = 1
  end

  def test_should_use_custom_value
    assert_equal 1, @state.value
  end

  def test_should_allow_lookup_by_custom_value
    assert_equal @state, @machine.states[1, :value]
  end
end

