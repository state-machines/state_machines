require_relative '../../test_helper'

class MachineWithCustomActionTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new, action: :save)
  end

  def test_should_use_the_custom_action
    assert_equal :save, @machine.action
  end
end
