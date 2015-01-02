require_relative '../../test_helper'

class MachineWithExistingMachinesOnOwnerClassTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @second_machine = StateMachines::Machine.new(@klass, :status, initial: :idling)
    @object = @klass.new
  end

  def test_should_track_each_state_machine
    expected = { state: @machine, status: @second_machine }
    assert_equal expected, @klass.state_machines
  end

  def test_should_initialize_state_for_both_machines
    assert_equal 'parked', @object.state
    assert_equal 'idling', @object.status
  end
end
