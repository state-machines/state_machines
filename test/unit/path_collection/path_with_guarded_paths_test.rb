require_relative '../../test_helper'
class PathWithGuardedPathsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling, :first_gear
    @machine.event :ignite do
      transition parked: :idling, if: lambda { false }
    end

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_not_enumerate_paths_if_guard_enabled
    assert_equal [], StateMachines::PathCollection.new(@object, @machine)
  end

  def test_should_enumerate_paths_if_guard_disabled
    paths = StateMachines::PathCollection.new(@object, @machine, guard: false)
    assert_equal [[
      StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    ]], paths
  end
end
