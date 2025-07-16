# frozen_string_literal: true

require 'test_helper'

class TransitionWithFiberDisabledTest < StateMachinesTest
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

  def test_should_run_callbacks_synchronously_with_fiber_false
    @machine.before_transition do
      @object.callbacks << :before
    end

    @machine.after_transition do
      @object.callbacks << :after
    end

    result = @transition.run_callbacks(fiber: false) { { success: true } }

    assert result
    assert_equal %i[before after], @object.callbacks
    refute_predicate @transition, :paused?
  end

  def test_should_not_support_pause_with_fiber_false
    @machine.around_transition do |block|
      @object.callbacks << :around_before
      # This pause should be ignored when fiber: false
      @transition.send(:pause)
      @object.callbacks << :around_after_pause
      block.call
      @object.callbacks << :around_after
    end

    result = @transition.run_callbacks(fiber: false) { { success: true } }

    assert result
    # All callbacks should execute in order without pausing
    assert_equal %i[around_before around_after_pause around_after], @object.callbacks
    refute_predicate @transition, :paused?
  end

  def test_should_handle_exceptions_without_fiber
    @machine.before_transition do
      @object.callbacks << :before
      raise 'Test error'
    end

    assert_raises(RuntimeError) do
      @transition.run_callbacks(fiber: false) { { success: true } }
    end

    assert_equal [:before], @object.callbacks
    refute_predicate @transition, :paused?
  end

  def test_should_handle_halted_callbacks_without_fiber
    @machine.before_transition do
      @object.callbacks << :before
      throw :halt
    end

    @machine.after_transition do
      @object.callbacks << :after
    end

    result = @transition.run_callbacks(fiber: false) { { success: true } }

    refute result
    assert_equal [:before], @object.callbacks
    refute_predicate @transition, :paused?
  end

  def test_should_handle_nested_around_callbacks_without_fiber
    @machine.around_transition do |block|
      @object.callbacks << :around_1_before
      block.call
      @object.callbacks << :around_1_after
    end

    @machine.around_transition do |block|
      @object.callbacks << :around_2_before
      block.call
      @object.callbacks << :around_2_after
    end

    result = @transition.run_callbacks(fiber: false) do
      @object.callbacks << :action
      { success: true }
    end

    assert result
    assert_equal %i[around_1_before around_2_before action around_2_after around_1_after], @object.callbacks
    refute_predicate @transition, :paused?
  end

  def test_should_not_create_fiber_when_disabled
    # Track fiber creation by checking if pause is ever available
    fiber_created = false

    @machine.around_transition do |block|
      # In fiber mode, this would create a fiber and allow pausing
      # With fiber: false, @paused_fiber should never be set
      fiber_created = true if @transition.instance_variable_get(:@paused_fiber)
      block.call
    end

    @transition.run_callbacks(fiber: false) { { success: true } }

    refute fiber_created, 'Fiber should not be created when fiber: false'
  end

  def test_fiber_option_should_be_passed_through_transition_collection
    # This test verifies the integration between TransitionCollection and Transition
    @transitions = [@transition]
    @collection = StateMachines::TransitionCollection.new(@transitions, fiber: false)

    @machine.around_transition do |block|
      @object.callbacks << :around_before
      # This pause should be ignored
      @transition.send(:pause)
      @object.callbacks << :around_after_pause
      block.call
    end

    # Use perform method which properly initializes the collection
    @collection.perform { { success: true } }

    # Should execute all callbacks without pausing
    assert_equal %i[around_before around_after_pause], @object.callbacks
    refute_predicate @transition, :paused?
  end
end
