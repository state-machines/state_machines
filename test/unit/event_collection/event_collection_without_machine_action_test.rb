require_relative '../../test_helper'

class EventCollectionWithoutMachineActionTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @events = StateMachines::EventCollection.new(@machine)
    @events << StateMachines::Event.new(@machine, :ignite)
    @machine.events.concat(@events)

    @object = @klass.new
  end

  def test_should_not_have_an_attribute_transition
    assert_nil @events.attribute_transition_for(@object)
  end
end

