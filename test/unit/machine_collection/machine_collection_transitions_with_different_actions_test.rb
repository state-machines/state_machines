require_relative '../../test_helper'

class MachineCollectionTransitionsWithDifferentActionsTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machines = StateMachines::MachineCollection.new
    @machines[:state] = @state = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
    @state.event :ignite do
      transition parked: :idling
    end
    @machines[:status] = @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :persist)
    @status.event :shift_up do
      transition first_gear: :second_gear
    end

    @object = @klass.new
    @object.state_event = 'ignite'
    @object.status_event = 'shift_up'
    @transitions = @machines.transitions(@object, :save)
  end

  def test_should_only_select_matching_actions
    assert_equal 1, @transitions.length
  end
end
