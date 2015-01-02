require_relative '../../test_helper'

class PathWithEncounteredTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling, :first_gear
    @machine.event :ignite do
      transition parked: :idling
    end
    @machine.event :park do
      transition idling: :parked
    end

    @object = @klass.new
    @object.state = 'parked'

    @path = StateMachines::Path.new(@object, @machine)
    @path.concat([
                     @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                     @park_transition = StateMachines::Transition.new(@object, @machine, :park, :idling, :parked)
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
end
