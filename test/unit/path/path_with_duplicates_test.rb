require_relative '../../test_helper'

class PathWithDuplicatesTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :park, :ignite

    @object = @klass.new
    @object.state = 'parked'

    @path = StateMachines::Path.new(@object, @machine)
    @path.concat([
                     @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                     @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked),
                     @ignite_again_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                 ])
  end

  def test_should_not_include_duplicates_in_from_states
    assert_equal [:parked, :idling], @path.from_states
  end

  def test_should_not_include_duplicates_in_to_states
    assert_equal [:idling, :parked], @path.to_states
  end

  def test_should_not_include_duplicates_in_events
    assert_equal [:ignite, :park], @path.events
  end
end
