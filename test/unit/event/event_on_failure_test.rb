require_relative '../../test_helper'
require_relative '../../files/integrations/event_on_failure_integration'

class EventOnFailureTest < StateMachinesTest
  def setup
    StateMachines::Integrations.reset
    StateMachines::Integrations.register(EventOnFailureIntegration)
    @klass = Class.new do
      attr_accessor :errors
    end

    @machine = StateMachines::Machine.new(@klass, integration: :event_on_failure_integration)
    @machine.state :parked
    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_invalidate_the_state
    @event.fire(@object)
    assert_equal ['cannot transition via "ignite"'], @object.errors
  end

  def test_should_run_failure_callbacks
    callback_args = nil
    @machine.after_failure { |*args| callback_args = args }

    @event.fire(@object)

    object, transition = callback_args
    assert_equal @object, object
    refute_nil transition
    assert_equal @object, transition.object
    assert_equal @machine, transition.machine
    assert_equal :ignite, transition.event
    assert_equal :parked, transition.from_name
    assert_equal :parked, transition.to_name
  end

  def teardown
    StateMachines::Integrations.reset
  end
end
