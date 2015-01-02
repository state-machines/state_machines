require_relative '../../test_helper'

class PathWithDeepTargetReachedTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite do
      transition parked: :idling
    end
    @machine.event :shift_up do
      transition parked: :first_gear
    end
    @machine.event :park do
      transition [:idling, :first_gear] => :parked
    end

    @object = @klass.new
    @object.state = 'parked'

    @path = StateMachines::Path.new(@object, @machine, target: :parked)
    @path.concat([
                     @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                     @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked),
                     @shift_up_transition = StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :first_gear),
                     @park_transition_2 = StateMachines::Transition.new(@object, @machine, :park, :first_gear, :parked)
                 ])
  end

  def test_should_be_complete
    assert_equal true, @path.complete?
  end

  def test_should_not_be_able_to_walk
    walked = false
    @path.walk { walked = true }
    assert_equal false, walked
  end

  def test_should_not_be_able_to_walk_with_available_transitions
    @machine.event :park do
      transition parked: same
    end

    walked = false
    @path.walk { walked = true }
    assert_equal false, walked
  end
end

