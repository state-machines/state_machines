require_relative '../../test_helper'

class AttributeTransitionCollectionWithBeforeCallbackHaltTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @machine.state :idling
    @machine.event :ignite

    @machine.before_transition { throw :halt }

    @object = @klass.new
    @object.state_event = 'ignite'

    @transitions = StateMachines::AttributeTransitionCollection.new([
      StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    ])
    @result = @transitions.perform
  end

  def test_should_not_succeed
    assert_equal false, @result
  end

  def test_should_not_clear_event
    assert_equal :ignite, @object.state_event
  end

  def test_should_not_write_event_transition
    assert_nil @object.send(:state_event_transition)
  end
end
