# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class TransitionFiberDeadlockTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :state

      def initialize
        @state = 'waiting'
      end

      state_machine :state, initial: :waiting do
        event :proceed do
          transition waiting: :processing
        end

        around_transition do |_object, _transition, block|
          # This test simulates the deadlock scenario mentioned in issue #152
          # where nested Fibers cause Thread.current conflicts

          # Create a nested fiber that uses Thread.current
          nested_fiber = Fiber.new do
            # This would previously cause issues with Thread.current[:state_machine_fiber_pausable]
            Thread.current[:test_marker] = :nested_value
            Fiber.yield :nested_started
            Thread.current[:test_marker] = :nested_finished
          end

          nested_fiber.resume
          block.call
          nested_fiber.resume if nested_fiber.alive?
        end
      end
    end
  end

  def test_should_not_cause_deadlock_with_nested_fibers
    # This test reproduces the scenario described in issue #152
    # With the bug using Thread.current, this could cause conflicts
    # With the fix using Fiber.current, it should work properly
    object = @klass.new

    # This should complete without raising any ThreadError
    begin
      object.proceed

      assert_equal 'processing', object.state
    rescue ThreadError => e
      flunk "Deadlock occurred: #{e.message}"
    end
  end

  def test_multiple_transitions_in_fibers
    # Test that multiple state machine transitions can run in separate fibers
    # without Thread.current conflicts
    object1 = @klass.new
    object2 = @klass.new

    results = []

    fiber1 = Fiber.new do
      object1.proceed
      results << object1.state
    end

    fiber2 = Fiber.new do
      object2.proceed
      results << object2.state
    end

    fiber1.resume
    fiber2.resume

    assert_equal %w[processing processing], results
  end
end
