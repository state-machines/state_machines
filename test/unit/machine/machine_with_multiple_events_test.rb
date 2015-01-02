require_relative '../../test_helper'

class MachineWithMultipleEventsTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @park, @shift_down = @machine.event(:park, :shift_down) do
      transition first_gear: :parked
    end
  end

  def test_should_have_events
    assert_equal [@park, @shift_down], @machine.events.to_a
  end

  def test_should_define_transitions_for_each_event
    [@park, @shift_down].each { |event| assert_equal 1, event.branches.size }
  end

  def test_should_transition_the_same_for_each_event
    object = @klass.new
    object.state = 'first_gear'
    object.park
    assert_equal 'parked', object.state

    object = @klass.new
    object.state = 'first_gear'
    object.shift_down
    assert_equal 'parked', object.state
  end
end

