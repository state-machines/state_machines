require_relative '../../test_helper'

class TransitionTransientTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @transition.transient = true
  end

  def test_should_be_transient
    assert @transition.transient?
  end
end
