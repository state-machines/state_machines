require_relative '../../test_helper'

class MachineWithExistingEventTest < StateMachinesTest
  def setup
    @machine = StateMachines::Machine.new(Class.new)
    @event = @machine.event(:ignite)
    @same_event = @machine.event(:ignite)
  end

  def test_should_not_create_new_event
    assert_same @event, @same_event
  end

  def test_should_allow_accessing_event_without_block
    assert_equal @event, @machine.event(:ignite)
  end
end
