# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class TransitionThreadStoragePreservationTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :state
      attr_reader :thread_storage_ids

      def initialize
        @state = 'waiting'
        @thread_storage_ids = []
      end

      def capture_thread_storage_id(label)
        # Create a unique thread-local store if it doesn't exist
        Thread.current[:test_store] ||= []
        @thread_storage_ids << [label, Thread.current[:test_store].object_id]
      end

      state_machine :state, initial: :waiting do
        event :proceed do
          transition waiting: :processing
        end

        before_transition do |object|
          object.capture_thread_storage_id(:before_transition)
        end

        after_transition do |object|
          object.capture_thread_storage_id(:after_transition)
        end

        around_transition do |object, _transition, block|
          object.capture_thread_storage_id(:around_before)
          block.call
          object.capture_thread_storage_id(:around_after)
        end
      end
    end
  end

  def test_thread_storage_consistency_across_callbacks
    # This test ensures that Thread.current storage remains consistent
    # across all callback types (before, around, after) in fiber mode
    object = @klass.new
    object.proceed

    # Extract the object IDs from each callback
    storage_ids = object.thread_storage_ids.map { |label, id| [label, id] }
    
    # All callbacks should see the same Thread.current[:test_store] object
    unique_ids = storage_ids.map { |_, id| id }.uniq
    
    assert_equal 1, unique_ids.length, 
      "Thread storage object_id should be consistent across all callbacks. Got: #{storage_ids.inspect}"
    
    # Verify we captured all expected callbacks
    expected_labels = [:before_transition, :around_before, :around_after, :after_transition]
    actual_labels = storage_ids.map { |label, _| label }
    
    assert_equal expected_labels, actual_labels, 
      "All expected callbacks should have been executed"
  end

  def test_thread_storage_works_with_fiber_disabled
    # Test that the fix doesn't break fiber-disabled mode
    @klass.class_eval do
      state_machine :state, initial: :waiting do
        event :proceed_sync do
          transition waiting: :processing
        end

        before_transition :if => lambda { |obj, trans| trans.event == :proceed_sync }, :do => lambda { |object|
          object.capture_thread_storage_id(:before_sync)
        }

        after_transition :if => lambda { |obj, trans| trans.event == :proceed_sync }, :do => lambda { |object|
          object.capture_thread_storage_id(:after_sync)
        }
      end
    end

    object = @klass.new
    # Use a transition collection to explicitly disable fibers
    transition = StateMachines::Transition.new(object, object.class.state_machine, :proceed_sync, :waiting, :processing)
    transition.run_callbacks(fiber: false) { { success: true } }

    storage_ids = object.thread_storage_ids.map { |label, id| [label, id] }
    unique_ids = storage_ids.map { |_, id| id }.uniq
    
    assert_equal 1, unique_ids.length, 
      "Thread storage should be consistent even with fiber: false"
  end

  def test_thread_storage_with_nested_callbacks
    # Test more complex callback scenarios
    @klass.class_eval do
      state_machine :state, initial: :waiting do
        event :complex_proceed do
          transition waiting: :processing
        end

        before_transition lambda { |obj, trans| trans.event == :complex_proceed } do |object|
          object.capture_thread_storage_id(:before_complex)
          # Modify thread storage during callback
          Thread.current[:nested_data] = 'nested_value'
        end

        around_transition lambda { |obj, trans| trans.event == :complex_proceed } do |object, _, block|
          object.capture_thread_storage_id(:around_complex_before)
          # Access the nested data set in before callback
          Thread.current[:nested_check] = Thread.current[:nested_data]
          block.call
          object.capture_thread_storage_id(:around_complex_after)
        end

        after_transition lambda { |obj, trans| trans.event == :complex_proceed } do |object|
          object.capture_thread_storage_id(:after_complex)
          # Ensure nested data is still available
          Thread.current[:final_check] = Thread.current[:nested_data]
        end
      end
    end

    object = @klass.new
    object.fire_state_event(:complex_proceed)

    # Check that thread storage is preserved
    storage_ids = object.thread_storage_ids.map { |label, id| [label, id] }
    unique_ids = storage_ids.map { |_, id| id }.uniq
    
    assert_equal 1, unique_ids.length, 
      "Thread storage should remain consistent in complex callback scenarios"
      
    # Verify that nested thread data was preserved across callbacks
    assert_equal 'nested_value', Thread.current[:nested_check]
    assert_equal 'nested_value', Thread.current[:final_check]
  end
end