require_relative '../../test_helper'

class PathWithAvailableTransitionsAfterReachingTargetTest < StateMachinesTest
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
                     @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)
                 ])
  end

  def test_should_be_complete
    assert_equal true, @path.complete?
  end

  def test_should_be_able_to_walk
    paths = []
    @path.walk { |path| paths << path }
    assert_equal [
                     [@ignite_transition, @park_transition, StateMachines::Transition.new(@object, @machine, :shift_up, :parked, :first_gear)]
                 ], paths
  end
end

