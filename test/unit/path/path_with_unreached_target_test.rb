require_relative '../../test_helper'

class PathWithUnreachedTargetTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite do
      transition parked: :idling
    end

    @object = @klass.new
    @object.state = 'parked'

    @path = StateMachines::Path.new(@object, @machine, target: :parked)
    @path.concat([
                     @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                 ])
  end

  def test_should_not_be_complete
    assert_equal false, @path.complete?
  end

  def test_should_not_be_able_to_walk
    walked = false
    @path.walk { walked = true }
    assert_equal false, walked
  end
end

