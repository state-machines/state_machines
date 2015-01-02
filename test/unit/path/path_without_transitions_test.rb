require_relative '../../test_helper'

class PathWithoutTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new

    @path = StateMachines::Path.new(@object, @machine)
    @path.concat([
                     @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                 ])
  end

  def test_should_not_be_able_to_walk_anywhere
    walked = false
    @path.walk { walked = true }
    assert_equal false, walked
  end
end

