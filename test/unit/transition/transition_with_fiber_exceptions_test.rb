# frozen_string_literal: true

require 'test_helper'

class TransitionWithFiberExceptionsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :callbacks

      def initialize
        @callbacks = []
      end
    end

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.state :idling
    @machine.event :ignite

    @object = @klass.new
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_catch_and_reraise_exception_in_before_callback
    @exception = RuntimeError.new('callback error')

    @machine.before_transition do
      @object.callbacks << :before
      raise @exception
    end

    assert_raises(RuntimeError) do
      @transition.run_callbacks { { success: true } }
    end

    # Should have cleaned up the paused fiber
    refute_predicate @transition, :paused?
  end

  def test_should_catch_and_reraise_exception_in_after_callback
    @exception = RuntimeError.new('after callback error')

    @machine.after_transition do
      @object.callbacks << :after
      raise @exception
    end

    assert_raises(RuntimeError) do
      @transition.run_callbacks { { success: true } }
    end

    # Should have cleaned up the paused fiber
    refute_predicate @transition, :paused?
  end

  def test_should_catch_and_reraise_exception_in_around_callback_before_yield
    @exception = RuntimeError.new('around before error')

    @machine.around_transition do |_block|
      @object.callbacks << :around_before
      raise @exception
    end

    assert_raises(RuntimeError) do
      @transition.run_callbacks { { success: true } }
    end

    # Should have cleaned up the paused fiber
    refute_predicate @transition, :paused?
  end

  def test_should_catch_and_reraise_exception_in_around_callback_after_yield
    @exception = RuntimeError.new('around after error')

    @machine.around_transition do |block|
      @object.callbacks << :around_before
      block.call
      @object.callbacks << :around_after
      raise @exception
    end

    assert_raises(RuntimeError) do
      @transition.run_callbacks { { success: true } }
    end

    # Should have cleaned up the paused fiber
    refute_predicate @transition, :paused?
  end

  def test_should_catch_and_reraise_exception_in_action_block
    @exception = RuntimeError.new('action error')

    assert_raises(RuntimeError) do
      @transition.run_callbacks do
        @object.callbacks << :action
        raise @exception
      end
    end

    # Should have cleaned up the paused fiber
    refute_predicate @transition, :paused?

    # Should have executed callbacks before the exception
    assert_includes @object.callbacks, :action
  end

  def test_should_catch_and_reraise_exception_when_resuming_paused_transition
    @exception = RuntimeError.new('resume error')

    @machine.around_transition do |block|
      @object.callbacks << :around_before_1
      block.call
      @object.callbacks << :around_after_1
    end

    @machine.around_transition do |block|
      @object.callbacks << :around_before_2
      block.call
      @object.callbacks << :around_after_2
      raise @exception
    end

    # First perform with after: false to pause
    @transition.run_callbacks(after: false) { { success: true } }

    assert_predicate @transition, :paused?
    assert_equal %i[around_before_1 around_before_2], @object.callbacks

    # Resume should catch and reraise the exception
    assert_raises(RuntimeError) do
      @transition.run_callbacks(after: true)
    end

    # Should have cleaned up the paused fiber
    refute_predicate @transition, :paused?

    # The exception is raised AFTER :around_after_2 is added, so we see it in callbacks
    # But :around_after_1 won't execute because the exception prevents the outer callback from completing
    assert_equal %i[around_before_1 around_before_2 around_after_2], @object.callbacks
  end

  def test_should_preserve_exception_type_and_message
    @exception = ArgumentError.new('specific error message')

    @machine.before_transition do
      raise @exception
    end

    begin
      @transition.run_callbacks { { success: true } }

      flunk 'Expected exception to be raised'
    rescue StandardError => e
      assert_instance_of ArgumentError, e
      assert_equal 'specific error message', e.message
    end
  end

  def test_should_clean_up_fiber_state_on_exception
    @exception = RuntimeError.new('cleanup test')

    @machine.around_transition do |block|
      @object.callbacks << :around_before
      block.call
      raise @exception
    end

    # Pause the transition
    @transition.run_callbacks(after: false) { { success: true } }

    assert_predicate @transition, :paused?

    # Resume with exception
    assert_raises(RuntimeError) do
      @transition.run_callbacks(after: true)
    end

    # Verify state is cleaned up
    refute_predicate @transition, :paused?
    assert_nil @transition.instance_variable_get(:@paused_fiber)
    refute @transition.instance_variable_get(:@resuming)
  end
end
