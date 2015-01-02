require_relative '../../test_helper'

class TransitionWithDynamicToValueTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked
    @machine.state :idling, value: lambda { 1 }
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_evaluate_to_value
    assert_equal 1, @transition.to
  end
end
