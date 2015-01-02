require_relative '../../test_helper'

class PathWithGuardedTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite
    @machine.event :shift_up do
      transition idling: :first_gear, if: lambda { false }
    end

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_not_walk_transitions_if_guard_enabled
    path = StateMachines::Path.new(@object, @machine)
    path.concat([
                    StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                ])

    paths = []
    path.walk { |next_path| paths << next_path }

    assert_equal [], paths
  end

  def test_should_not_walk_transitions_if_guard_disabled
    path = StateMachines::Path.new(@object, @machine, guard: false)
    path.concat([
                    ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                ])

    paths = []
    path.walk { |next_path| paths << next_path }

    assert_equal [
                     [ignite_transition, StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)]
                 ], paths
  end
end
