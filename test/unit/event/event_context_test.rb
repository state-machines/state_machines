require_relative '../../test_helper'

class EventContextTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite, human_name: 'start')
  end

  def test_should_evaluate_within_the_event
    scope = nil
    @event.context { scope = self }
    assert_equal @event, scope
  end
end

