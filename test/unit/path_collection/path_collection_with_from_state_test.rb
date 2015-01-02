require_relative '../../test_helper'

class PathCollectionWithFromStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling, :first_gear
    @machine.event :park do
      transition idling: :parked
    end

    @object = @klass.new
    @object.state = 'parked'

    @paths = StateMachines::PathCollection.new(@object, @machine, from: :idling)
  end

  def test_should_generate_paths_from_custom_from_state
    assert_equal [[
      StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)
    ]], @paths
  end

  def test_should_have_a_from_name
    assert_equal :idling, @paths.from_name
  end
end
