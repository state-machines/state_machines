# frozen_string_literal: true

require 'test_helper'

class TransitionThreadCurrentPreservationTest < StateMachinesTest
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
      end
    end
  end

  def test_should_preserve_thread_current_object_identity_across_callbacks
    # This test reproduces issue #152 and verifies the fix
    object_ids = []

    # Initialize some thread-local storage
    Thread.current[:test_store] = { value: 'test' }
    original_object_id = Thread.current[:test_store].object_id

    @klass.state_machine.before_transition do |obj, transition|
      object_ids << Thread.current[:test_store].object_id
    end

    @klass.state_machine.around_transition do |obj, transition, block|
      object_ids << Thread.current[:test_store].object_id
      block.call
      object_ids << Thread.current[:test_store].object_id
    end

    @klass.state_machine.after_transition do |obj, transition|
      object_ids << Thread.current[:test_store].object_id
    end

    # Run the transition
    object = @klass.new
    object.proceed

    # All callbacks should see the same Thread.current[:test_store] object_id
    assert_equal [original_object_id] * 4, object_ids,
                 "Thread.current[:test_store] object_id should be preserved across all callbacks"

    # Verify the object itself is still accessible and correct
    assert_equal 'test', Thread.current[:test_store][:value]
    assert_equal original_object_id, Thread.current[:test_store].object_id
  end

  def test_should_preserve_multiple_thread_locals
    # Test that multiple Thread.current keys are preserved
    Thread.current[:store1] = { name: 'store1' }
    Thread.current[:store2] = { name: 'store2' }

    original_ids = {
      store1: Thread.current[:store1].object_id,
      store2: Thread.current[:store2].object_id
    }

    collected_ids = { store1: [], store2: [] }

    @klass.state_machine.before_transition do |obj, transition|
      collected_ids[:store1] << Thread.current[:store1].object_id
      collected_ids[:store2] << Thread.current[:store2].object_id
    end

    @klass.state_machine.after_transition do |obj, transition|
      collected_ids[:store1] << Thread.current[:store1].object_id
      collected_ids[:store2] << Thread.current[:store2].object_id
    end

    object = @klass.new
    object.proceed

    # Both stores should maintain their object identity
    assert_equal [original_ids[:store1]] * 2, collected_ids[:store1]
    assert_equal [original_ids[:store2]] * 2, collected_ids[:store2]
  end

  def test_should_handle_nil_thread_locals_gracefully
    # Test that nil thread locals don't cause issues
    Thread.current[:nil_store] = nil

    @klass.state_machine.before_transition do |obj, transition|
      # Should not raise an error
      Thread.current[:nil_store]
    end

    object = @klass.new
    # Should not raise an error
    object.proceed
    assert true
  end

  def test_should_allow_thread_local_modification_in_fiber
    # Test that modifications in callbacks are preserved
    Thread.current[:modifiable] = { count: 0 }
    original_object_id = Thread.current[:modifiable].object_id

    @klass.state_machine.before_transition do |obj, transition|
      Thread.current[:modifiable][:count] += 1
    end

    @klass.state_machine.around_transition do |obj, transition, block|
      Thread.current[:modifiable][:count] += 10
      block.call
      Thread.current[:modifiable][:count] += 100
    end

    @klass.state_machine.after_transition do |obj, transition|
      Thread.current[:modifiable][:count] += 1000
    end

    object = @klass.new
    object.proceed

    # The object should be the same and modifications should be preserved
    assert_equal original_object_id, Thread.current[:modifiable].object_id
    assert_equal 1111, Thread.current[:modifiable][:count]  # 1 + 10 + 100 + 1000
  end
end
