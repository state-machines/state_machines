require_relative '../../test_helper'

class EventWithMatchingDisabledTransitionsTest < StateMachinesTest
  module Custom
    include StateMachines::Integrations::Base

    def invalidate(object, _attribute, message, values = [])
      (object.errors ||= []) << generate_message(message, values)
    end

    def reset(object)
      object.errors = []
    end
  end

  def setup
    StateMachines::Integrations.register(EventWithMatchingDisabledTransitionsTest::Custom)

    @klass = Class.new do
      attr_accessor :errors
    end

    @machine = StateMachines::Machine.new(@klass, integration: :custom)
    @machine.state :parked, :idling

    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition(parked: :idling, if: lambda { false })

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_not_be_able_to_fire
    refute @event.can_fire?(@object)
  end

  def test_should_be_able_to_fire_with_disabled_guards
    assert @event.can_fire?(@object, guard: false)
  end

  def test_should_not_have_a_transition
    assert_nil @event.transition_for(@object)
  end

  def test_should_have_a_transition_with_disabled_guards
    refute_nil @event.transition_for(@object, guard: false)
  end

  def test_should_not_fire
    refute @event.fire(@object)
  end

  def test_should_not_change_the_current_state
    @event.fire(@object)
    assert_equal 'parked', @object.state
  end

  def test_should_invalidate_the_state
    @event.fire(@object)
    assert_equal ['cannot transition via "ignite"'], @object.errors
  end

  def test_should_invalidate_with_human_event_name
    @event.human_name = 'start'
    @event.fire(@object)
    assert_equal ['cannot transition via "start"'], @object.errors
  end

  def test_should_invalid_with_human_state_name_if_specified
    klass = Class.new do
      attr_accessor :errors
    end

    machine = StateMachines::Machine.new(klass, integration: :custom, messages: { invalid_transition: 'cannot transition via "%s" from "%s"' })
    parked, idling = machine.state :parked, :idling
    parked.human_name = 'stopped'

    machine.events << event = StateMachines::Event.new(machine, :ignite)
    event.transition(parked: :idling, if: lambda { false })

    object = @klass.new
    object.state = 'parked'

    event.fire(object)
    assert_equal ['cannot transition via "ignite" from "stopped"'], object.errors
  end

  def test_should_reset_existing_error
    @object.errors = ['invalid']

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

