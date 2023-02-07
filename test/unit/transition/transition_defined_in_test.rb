require_relative '../../test_helper'

class TransitionDefinedTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @caller = caller[0]

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling, true, @caller)
  end

  def test_defined_in_should_set
    assert @transition.defined_in == @caller
  end
end
