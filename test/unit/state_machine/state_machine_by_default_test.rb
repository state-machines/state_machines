require_relative '../../test_helper'

class StateMachineByDefaultTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = @klass.state_machine
  end

  def test_should_use_state_attribute
    assert_equal :state, @machine.attribute
  end
end
