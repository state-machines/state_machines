require_relative '../../test_helper'

class PathCollectionWithDuplicateNodesTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :shift_up do
      transition parked: :idling, idling: :first_gear
    end
    @machine.event :park do
      transition first_gear: :idling
    end
    @object = @klass.new
    @object.state = 'parked'

    @paths = StateMachines::PathCollection.new(@object, @machine)
  end

  def test_should_not_include_duplicates_in_from_states
    assert_equal [:parked, :idling, :first_gear], @paths.from_states
  end

  def test_should_not_include_duplicates_in_to_states
    assert_equal [:idling, :first_gear], @paths.to_states
  end

  def test_should_not_include_duplicates_in_events
    assert_equal [:shift_up, :park], @paths.events
  end
end
