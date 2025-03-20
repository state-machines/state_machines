require_relative '../../test_helper'

class MachineFinderWithOtherNamedExistingOnSameClassTest < StateMachinesTest
  def setup
    @klass = Class.new
    @existing_machine = StateMachines::Machine.new(@klass, :status)
    @machine = StateMachines::Machine.find_or_create(@klass)
  end

  def test_should_create_a_new_machine
    refute_same @machine, @existing_machine
  end
end

