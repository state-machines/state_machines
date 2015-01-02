require_relative '../../test_helper'

class EventCollectionAttributeWithNamespacedMachineTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def save
      end
    end

    @machine = StateMachines::Machine.new(@klass, namespace: 'alarm', initial: :active, action: :save)
    @events = StateMachines::EventCollection.new(@machine)

    @machine.state :active, :off
    @events << @disable = StateMachines::Event.new(@machine, :disable)
    @machine.events.concat(@events)

    @object = @klass.new
  end

  def test_should_not_have_transition_if_nil
    @object.state_event = nil
    assert_nil @events.attribute_transition_for(@object)
  end

  def test_should_have_invalid_transition_if_event_cannot_be_fired
    @object.state_event = 'disable'
    assert_equal false, @events.attribute_transition_for(@object)
  end

  def test_should_have_valid_transition_if_event_can_be_fired
    @disable.transition active: :off
    @object.state_event = 'disable'

    assert_instance_of StateMachines::Transition, @events.attribute_transition_for(@object)
  end
end
