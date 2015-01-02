require_relative '../../test_helper'

class EventCollectionAttributeWithMachineActionTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def save
      end
    end

    @machine = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @events = StateMachines::EventCollection.new(@machine)

    @machine.state :parked, :idling
    @events << @ignite = StateMachines::Event.new(@machine, :ignite)
    @machine.events.concat(@events)

    @object = @klass.new
  end

  def test_should_not_have_transition_if_nil
    @object.state_event = nil
    assert_nil @events.attribute_transition_for(@object)
  end

  def test_should_not_have_transition_if_empty
    @object.state_event = ''
    assert_nil @events.attribute_transition_for(@object)
  end

  def test_should_have_invalid_transition_if_invalid_event_specified
    @object.state_event = 'invalid'
    assert_equal false, @events.attribute_transition_for(@object)
  end

  def test_should_have_invalid_transition_if_event_cannot_be_fired
    @object.state_event = 'ignite'
    assert_equal false, @events.attribute_transition_for(@object)
  end

  def test_should_have_valid_transition_if_event_can_be_fired
    @ignite.transition parked: :idling
    @object.state_event = 'ignite'

    assert_instance_of StateMachines::Transition, @events.attribute_transition_for(@object)
  end

  def test_should_have_valid_transition_if_already_defined_in_transition_cache
    @ignite.transition parked: :idling
    @object.state_event = nil
    @object.send(:state_event_transition=, transition = @ignite.transition_for(@object))

    assert_equal transition, @events.attribute_transition_for(@object)
  end

  def test_should_use_transition_cache_if_both_event_and_transition_are_present
    @ignite.transition parked: :idling
    @object.state_event = 'ignite'
    @object.send(:state_event_transition=, transition = @ignite.transition_for(@object))

    assert_equal transition, @events.attribute_transition_for(@object)
  end
end
