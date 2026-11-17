# frozen_string_literal: true

require 'test_helper'

class TransitionCollectionWithSkippedAfterCallbacksAndAroundCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @callbacks = []

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.state :idling
    @machine.event :ignite
    @machine.around_transition do |block|
      @callbacks << :around_before
      block.call
      @callbacks << :around_after
    end

    @object = @klass.new

    @transitions = StateMachines::TransitionCollection.new([
                                                             @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
                                                           ], after: false)
  end

  def test_should_succeed
    @transitions.perform

    assert @transitions.perform
  end

  def test_should_not_enter_around_callbacks
    @transitions.perform

    assert_empty @callbacks
  end

  def test_should_run_around_callbacks_after_yield_on_subsequent_perform
    @transitions.perform
    StateMachines::TransitionCollection.new([@transition]).perform

    assert_includes @callbacks, :around_after
  end

  def test_should_run_the_around_callback_once_around_the_subsequent_perform
    @transitions.perform
    StateMachines::TransitionCollection.new([@transition]).perform

    assert_equal %i[around_before around_after], @callbacks
  end
end
