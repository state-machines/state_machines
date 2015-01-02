require_relative '../../test_helper'

class MachineWithExistingMachinesWithSameAttributesOnOwnerSubclassTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @second_machine = StateMachines::Machine.new(@klass, :public_state, initial: :idling, attribute: :state)

    @subclass = Class.new(@klass)
    @object = @subclass.new
  end

  def test_should_not_copy_sibling_machines_to_subclass_after_initialization
    @subclass.state_machine(:state) {}
    assert_equal @klass.state_machine(:public_state), @subclass.state_machine(:public_state)
  end

  def test_should_copy_sibling_machines_to_subclass_after_new_state
    subclass_machine = @subclass.state_machine(:state) {}
    subclass_machine.state :first_gear
    refute_equal @klass.state_machine(:public_state), @subclass.state_machine(:public_state)
  end

  def test_should_copy_new_states_to_sibling_machines
    subclass_machine = @subclass.state_machine(:state) {}
    @first_gear = subclass_machine.state :first_gear

    second_subclass_machine = @subclass.state_machine(:public_state)
    assert_equal @first_gear, second_subclass_machine.state(:first_gear)
  end
end
