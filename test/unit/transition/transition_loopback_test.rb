require_relative '../../test_helper'

class TransitionLoopbackTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked
    @machine.event :park

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :park, :parked, :parked)
  end

  def test_should_be_loopback
    assert @transition.loopback?
  end
end
