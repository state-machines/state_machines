require_relative '../../test_helper'

class MachineCollectionTransitionsWithSameActionsTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @machine = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @machine.event :ignite do
      transition parked: :idling
    end
    @machines[:status] = @machine = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save)
    @machine.event :shift_up do
      transition first_gear: :second_gear
    end

    @object = @klass.new
    @object.state_event = 'ignite'
    @object.status_event = 'shift_up'
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_not_be_empty
    assert_equal 2, @transitions.length
  end

  def test_should_perform
    assert_equal true, @transitions.perform
  end
end

