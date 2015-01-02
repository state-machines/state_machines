require_relative '../../test_helper'

class PathCollectionWithDeepPathsTest < StateMachinesTest
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

    @paths = StateMachines::PathCollection.new(@object, @machine, to: :idling, deep: true)
  end

  def test_should_allow_target_to_be_reached_more_than_once_per_path
    assert_equal [
      [
        StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
      ],
      [
        StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
        StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear),
        StateMachines::Transition.new(@object, @machine, :shift_down, :first_gear, :idling)
      ],
      [
        StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :idling)
      ],
      [
        StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :idling),
        StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear),
        StateMachines::Transition.new(@object, @machine, :shift_down, :first_gear, :idling)
      ]
    ], @paths
  end
end
