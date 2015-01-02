require_relative '../../test_helper'

class MachineAfterChangingOwnerClassTest < StateMachinesTest
  def setup
    @original_class = Class.new
    @machine = StateMachines::Machine.new(@original_class)

    @new_class = Class.new(@original_class)
    @new_machine = @machine.clone
    @new_machine.owner_class = @new_class

    @object = @new_class.new
  end

  def test_should_update_owner_class
    assert_equal @new_class, @new_machine.owner_class
  end

  def test_should_not_change_original_owner_class
    assert_equal @original_class, @machine.owner_class
  end

  def test_should_change_the_associated_machine_in_the_new_class
    assert_equal @new_machine, @new_class.state_machines[:state]
  end

  def test_should_not_change_the_associated_machine_in_the_original_class
    assert_equal @machine, @original_class.state_machines[:state]
  end
end

