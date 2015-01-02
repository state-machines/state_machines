require_relative '../../test_helper'

class PathCollectionWithToStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite do
      transition parked: :idling
    end
    @machine.event :shift_up do
      transition parked: :idling, idling: :first_gear
    end
    @machine.event :shift_down do
      transition first_gear: :idling
    end
    @object = @klass.new
    @object.state = 'parked'

    @paths = StateMachines::PathCollection.new(@object, @machine, to: :idling)
  end

  def test_should_stop_paths_once_target_state_reached
    assert_equal [
      [StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)],
      [StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :idling)]
    ], @paths
  end
end
