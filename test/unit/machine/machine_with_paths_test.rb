require_relative '../../test_helper'

class MachineWithPathsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.event :ignite do
      transition parked: :idling
    end
    @machine.event :shift_up do
      transition first_gear: :second_gear
    end

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_have_paths
    assert_equal [[StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)]], @machine.paths_for(@object)
  end

  def test_should_allow_requirement_configuration
    assert_equal [[StateMachines::Transition.new(@object, @machine, :shift_up, :first_gear, :second_gear)]], @machine.paths_for(@object, from: :first_gear)
  end
end
