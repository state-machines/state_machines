require_relative '../../test_helper'

class EventWithMachineActionTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :saved

      def save
        @saved = true
      end
    end

    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling

    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition(parked: :idling)

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_run_action_on_fire
    @event.fire(@object)
    assert @object.saved
  end

  def test_should_not_run_action_if_configured_to_skip
    @event.fire(@object, false)
    refute @object.saved
  end
end

