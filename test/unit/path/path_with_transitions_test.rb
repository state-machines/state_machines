require_relative '../../test_helper'

class PathWithTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling, :first_gear
    @machine.event :ignite, :shift_up

    @object = @klass.new
    @object.state = 'parked'

    @path = StateMachines::Path.new(@object, @machine)
    @path.concat([
                     @ignite_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
                     @shift_up_transition = StateMachines::Transition.new(@object, @machine, :shift_up, :idling, :first_gear)
                 ])
  end

  def test_should_enumerate_transitions
    assert_equal [@ignite_transition, @shift_up_transition], @path
  end

  def test_should_have_a_from_name
    assert_equal :parked, @path.from_name
  end

  def test_should_have_from_states
    assert_equal [:parked, :idling], @path.from_states
  end

  def test_should_have_a_to_name
    assert_equal :first_gear, @path.to_name
  end

  def test_should_have_to_states
    assert_equal [:idling, :first_gear], @path.to_states
  end

  def test_should_have_events
    assert_equal [:ignite, :shift_up], @path.events
  end

  def test_should_not_be_able_to_walk_anywhere
    walked = false
    @path.walk { walked = true }
    assert_equal false, walked
  end

  def test_should_be_complete
    assert_equal true, @path.complete?
  end
end

