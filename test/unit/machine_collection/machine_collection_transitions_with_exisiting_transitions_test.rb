require 'test_helper'

class MachineCollectionTransitionsWithExisitingTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.send(:state_event_transition=, StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling))
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_not_be_empty
    assert_equal 1, @transitions.length
  end

  def test_should_perform
    assert_equal true, @transitions.perform
  end
end
