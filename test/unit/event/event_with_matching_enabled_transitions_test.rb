require_relative '../../test_helper'

class EventWithMatchingEnabledTransitionsTest < StateMachinesTest
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
    StateMachines::Integrations.register(EventWithMatchingEnabledTransitionsTest::Custom)

    @klass = Class.new do
      attr_accessor :errors
    end

    @machine = StateMachines::Machine.new(@klass, integration: :custom)
    @machine.state :parked, :idling

    @machine.events << @event = StateMachines::Event.new(@machine, :ignite)
    @event.transition(parked: :idling)

    @object = @klass.new
    @object.state = 'parked'
  end

  def test_should_be_able_to_fire
    assert @event.can_fire?(@object)
  end

  def test_should_have_a_transition
    transition = @event.transition_for(@object)
    refute_nil transition
    assert_equal 'parked', transition.from
    assert_equal 'idling', transition.to
    assert_equal :ignite, transition.event
  end

  def test_should_fire
    assert @event.fire(@object)
  end

  def test_should_change_the_current_state
    @event.fire(@object)
    assert_equal 'idling', @object.state
  end

  def test_should_reset_existing_error
    @object.errors = ['invalid']

    @event.fire(@object)
    assert_equal [], @object.errors
  end

  def test_should_not_invalidate_the_state
    @event.fire(@object)
    assert_equal [], @object.errors
  end

  def test_should_not_be_able_to_fire_on_reset
    @event.reset
    refute @event.can_fire?(@object)
  end

  def teardown
    StateMachines::Integrations.reset
  end
end

