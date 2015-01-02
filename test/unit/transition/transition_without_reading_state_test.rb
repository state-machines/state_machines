require_relative '../../test_helper'

class TransitionWithoutReadingStateTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'idling'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling, false)
  end

  def test_should_not_read_from_value_from_object
    assert_equal 'parked', @transition.from
  end

  def test_should_have_to_value
    assert_equal 'idling', @transition.to
  end
end
