require_relative '../../test_helper'

class TransitionWithCustomMachineAttributeTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, :state, attribute: :state_id)
    @machine.state :off, value: 1
    @machine.state :active, value: 2
    @machine.event :activate

    @object = @klass.new
    @object.state_id = 1

    @transition = StateMachines::Transition.new(@object, @machine, :activate, :off, :active)
  end

  def test_should_persist
    @transition.persist
    assert_equal 2, @object.state_id
  end

  def test_should_rollback
    @object.state_id = 2
    @transition.rollback

    assert_equal 1, @object.state_id
  end
end
