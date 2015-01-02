require_relative '../../test_helper'

class MachineWithCachedStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @state = @machine.state :parked, value: -> { Object.new }, cache: true

    @object = @klass.new
  end

  def test_should_use_evaluated_value
    assert_instance_of Object, @object.state
  end

  def test_use_same_value_across_multiple_objects
    assert_equal @object.state, @klass.new.state
  end
end

