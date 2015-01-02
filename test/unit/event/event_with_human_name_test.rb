require_relative '../../test_helper'

class EventWithHumanNameTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass)
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite, human_name: 'start')
  end

  def test_should_use_custom_human_name
    assert_equal 'start', @event.human_name
  end
end
