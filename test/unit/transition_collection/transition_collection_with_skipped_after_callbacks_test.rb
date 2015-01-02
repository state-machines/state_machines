require_relative '../../test_helper'

class TransitionCollectionWithSkippedAfterCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @callbacks = []

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.state :idling
    @machine.event :ignite
    @machine.after_transition { @callbacks << :after }

    @object = @klass.new

    @transitions = StateMachines::TransitionCollection.new([
      @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    ], after: false)
    @result = @transitions.perform
  end

  def test_should_succeed
    assert_equal true, @result
  end

  def test_should_not_run_after_callbacks
    refute @callbacks.include?(:after)
  end

  def test_should_run_after_callbacks_on_subsequent_perform
    StateMachines::TransitionCollection.new([@transition]).perform
    assert @callbacks.include?(:after)
  end
end
