require_relative '../../test_helper'

class PathCollectionWithPathsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling, :first_gear
    @machine.event :ignite do
      transition parked: :idling
    end
    @machine.event :shift_up do
      transition idling: :first_gear
    end

    @object = @klass.new
    @object.state = 'parked'

    @paths = StateMachines::PathCollection.new(@object, @machine)
  end

  def test_should_enumerate_paths
    assert_equal [[
      StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
      StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)
    ]], @paths
  end

  def test_should_have_a_from_name
    assert_equal :parked, @paths.from_name
  end

  def test_should_not_have_a_to_name
    assert_nil @paths.to_name
  end

  def test_should_have_from_states
    assert_equal [:parked, :idling], @paths.from_states
  end

  def test_should_have_to_states
    assert_equal [:idling, :first_gear], @paths.to_states
  end

  def test_should_have_no_events
    assert_equal [:ignite, :shift_up], @paths.events
  end
end
