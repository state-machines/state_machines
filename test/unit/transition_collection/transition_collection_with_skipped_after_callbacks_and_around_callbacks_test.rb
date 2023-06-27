require 'test_helper'

class TransitionCollectionWithSkippedAfterCallbacksAndAroundCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @callbacks = []

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.state :idling
    @machine.event :ignite
    @machine.around_transition { |block| @callbacks << :around_before; block.call; @callbacks << :around_after }

    @object = @klass.new

    @transitions = StateMachines::TransitionCollection.new([
      @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    ], after: false)
  end

  def test_should_raise_exception
    skip('test not supported in this Ruby Engine') if StateMachines::Transition.pause_supported?
    assert_raises(ArgumentError) { @transitions.perform }
  end

  def test_should_succeed
    skip('test not supported in this Ruby Engine') unless StateMachines::Transition.pause_supported?
    @transitions.perform
    assert_equal true, @transitions.perform
  end

  def test_should_not_run_around_callbacks_after_yield
    skip('test not supported in this Ruby Engine') unless StateMachines::Transition.pause_supported?

    @transitions.perform
    refute @callbacks.include?(:around_after)
  end

  def test_should_run_around_callbacks_after_yield_on_subsequent_perform
    skip('test not supported in this Ruby Engine') unless StateMachines::Transition.pause_supported?

    @transitions.perform
    StateMachines::TransitionCollection.new([@transition]).perform
    assert @callbacks.include?(:around_after)
  end

  def test_should_not_rerun_around_callbacks_before_yield_on_subsequent_perform
    skip('test not supported in this Ruby Engine') unless StateMachines::Transition.pause_supported?

    @transitions.perform
    @callbacks = []
    StateMachines::TransitionCollection.new([@transition]).perform
    refute @callbacks.include?(:around_before)
  end
end
