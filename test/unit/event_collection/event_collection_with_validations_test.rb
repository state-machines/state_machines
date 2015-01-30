require_relative '../../test_helper'

class EventCollectionWithValidationsTest < StateMachinesTest
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
    StateMachines::Integrations.register(EventCollectionWithValidationsTest::Custom)

    @klass = Class.new do
      attr_accessor :errors

      def initialize
        @errors = []
        super
      end
    end

    @machine = StateMachines::Machine.new(@klass, initial: :parked, action: :save, integration: :custom)
    @events = StateMachines::EventCollection.new(@machine)

    @parked, @idling = @machine.state :parked, :idling
    @events << @ignite = StateMachines::Event.new(@machine, :ignite)
    @machine.events.concat(@events)

    @object = @klass.new
  end

  def test_should_invalidate_if_invalid_event_specified
    @object.state_event = 'invalid'
    @events.attribute_transition_for(@object, true)

    assert_equal ['is invalid'], @object.errors
  end

  def test_should_invalidate_if_event_cannot_be_fired
    @object.state = 'idling'
    @object.state_event = 'ignite'
    @events.attribute_transition_for(@object, true)

    assert_equal ['cannot transition when idling'], @object.errors
  end

  def test_should_invalidate_with_human_name_if_invalid_event_specified
    @idling.human_name = 'waiting'
    @object.state = 'idling'
    @object.state_event = 'ignite'
    @events.attribute_transition_for(@object, true)

    assert_equal ['cannot transition when waiting'], @object.errors
  end

  def test_should_not_invalidate_event_can_be_fired
    @ignite.transition parked: :idling
    @object.state_event = 'ignite'
    @events.attribute_transition_for(@object, true)

    assert_equal [], @object.errors
  end

  def teardown
    StateMachines::Integrations.reset
  end
end

