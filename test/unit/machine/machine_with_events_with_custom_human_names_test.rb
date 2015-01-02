require_relative '../../test_helper'

class MachineWithEventsWithCustomHumanNamesTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @event = @machine.event(:ignite, human_name: 'start')
  end

  def test_should_use_custom_human_name
    assert_equal 'start', @event.human_name
  end

  def test_should_allow_human_state_name_lookup
    assert_equal 'start', @klass.human_state_event_name(:ignite)
  end
end

