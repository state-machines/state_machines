require_relative '../../test_helper'

class MachineFinderCustomOptionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.find_or_create(@klass, :status, initial: :parked)
    @object = @klass.new
  end

  def test_should_use_custom_attribute
    assert_equal :status, @machine.attribute
  end

  def test_should_set_custom_initial_state
    assert_equal :parked, @machine.initial_state(@object).name
  end
end
