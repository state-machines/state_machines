require_relative '../../test_helper'

class PathWithAvailableTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling, :first_gear
    @machine.event :ignite
    @machine.event :shift_up do
      transition idling: :first_gear
    end
    @machine.event :park do
      transition idling: :parked
    end

    @object = @klass.new
    @object.state = 'parked'

    @path = StateMachines::Path.new(@object, @machine)
    @path.concat([
                     @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                 ])
  end

  def test_should_not_be_complete
    refute @path.complete?
  end

  def test_should_walk_each_available_transition
    paths = []
    @path.walk { |path| paths << path }

    assert_equal [
                     [@ignite_transition, StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)],
                     [@ignite_transition, StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)]
                 ], paths
  end

  def test_should_yield_path_instances_when_walking
    @path.walk do |path|
      assert_instance_of StateMachines::Path, path
    end
  end

  def test_should_not_modify_current_path_after_walking
    @path.walk {}
    assert_equal [@ignite_transition], @path
  end

  def test_should_not_modify_object_after_walking
    @path.walk {}
    assert_equal 'parked', @object.state
  end
end
