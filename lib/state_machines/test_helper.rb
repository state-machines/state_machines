# frozen_string_literal: true

module StateMachines
  # Test helper module providing assertion methods for state machine testing
  # Designed to work with Minitest, RSpec, and future testing frameworks
  #
  # @example Basic usage with Minitest
  #   class MyModelTest < Minitest::Test
  #     include StateMachines::TestHelper
  #
  #     def test_initial_state
  #       model = MyModel.new
  #       assert_state(model, :state_machine_name, :initial_state)
  #     end
  #   end
  #
  # @example Usage with RSpec
  #   RSpec.describe MyModel do
  #     include StateMachines::TestHelper
  #
  #     it "starts in initial state" do
  #       model = MyModel.new
  #       assert_state(model, :state_machine_name, :initial_state)
  #     end
  #   end
  #
  # @since 0.10.0
  module TestHelper
    # Assert that an object is in a specific state for a given state machine
    #
    # @param object [Object] The object with state machines
    # @param machine_name [Symbol] The name of the state machine
    # @param expected_state [Symbol] The expected state
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the state doesn't match
    #
    # @example
    #   user = User.new
    #   assert_state(user, :status, :active)
    def assert_state(object, machine_name, expected_state, message = nil)
      actual = object.send("#{machine_name}_name")
      default_message = "Expected #{object.class}##{machine_name} to be #{expected_state}, but was #{actual}"

      if defined?(::Minitest)
        assert_equal expected_state.to_s, actual.to_s, message || default_message
      elsif defined?(::RSpec)
        expect(actual.to_s).to eq(expected_state.to_s), message || default_message
      else
        raise "Expected #{expected_state}, but got #{actual}" unless expected_state.to_s == actual.to_s
      end
    end

    # Assert that an object can transition via a specific event
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event name
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the transition is not available
    #
    # @example
    #   user = User.new
    #   assert_can_transition(user, :activate)
    def assert_can_transition(object, event, message = nil)
      can_method = "can_#{event}?"
      default_message = "Expected to be able to trigger event :#{event}, but #{can_method} returned false"

      if defined?(::Minitest)
        assert object.send(can_method), message || default_message
      elsif defined?(::RSpec)
        expect(object.send(can_method)).to be_truthy, message || default_message
      else
        raise default_message unless object.send(can_method)
      end
    end

    # Assert that an object cannot transition via a specific event
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event name
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the transition is available
    #
    # @example
    #   user = User.new
    #   assert_cannot_transition(user, :delete)
    def assert_cannot_transition(object, event, message = nil)
      can_method = "can_#{event}?"
      default_message = "Expected not to be able to trigger event :#{event}, but #{can_method} returned true"

      if defined?(::Minitest)
        refute object.send(can_method), message || default_message
      elsif defined?(::RSpec)
        expect(object.send(can_method)).to be_falsy, message || default_message
      elsif object.send(can_method)
        raise default_message
      end
    end

    # Assert that triggering an event changes the object to the expected state
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event to trigger
    # @param machine_name [Symbol] The name of the state machine
    # @param expected_state [Symbol] The expected state after transition
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the transition fails or results in wrong state
    #
    # @example
    #   user = User.new
    #   assert_transition(user, :activate, :status, :active)
    def assert_transition(object, event, machine_name, expected_state, message = nil)
      object.send("#{event}!")
      assert_state(object, machine_name, expected_state, message)
    end

    # === Extended State Machine Assertions ===

    def assert_sm_states_list(machine, expected_states, message = nil)
      actual_states = machine.states.map(&:name).compact
      default_message = "Expected states #{expected_states} but got #{actual_states}"

      if defined?(::Minitest)
        assert_equal expected_states.sort, actual_states.sort, message || default_message
      elsif defined?(::RSpec)
        expect(actual_states.sort).to eq(expected_states.sort), message || default_message
      else
        raise default_message unless expected_states.sort == actual_states.sort
      end
    end

    def refute_sm_state_defined(machine, state, message = nil)
      state_exists = machine.states.any? { |s| s.name == state }
      default_message = "Expected state #{state} to not be defined in machine"

      if defined?(::Minitest)
        refute state_exists, message || default_message
      elsif defined?(::RSpec)
        expect(state_exists).to be_falsy, message || default_message
      elsif state_exists
        raise default_message
      end
    end
    alias assert_sm_state_not_defined refute_sm_state_defined

    def assert_sm_initial_state(machine, expected_state, message = nil)
      state_obj = machine.state(expected_state)
      is_initial = state_obj&.initial?
      default_message = "Expected state #{expected_state} to be the initial state"

      if defined?(::Minitest)
        assert is_initial, message || default_message
      elsif defined?(::RSpec)
        expect(is_initial).to be_truthy, message || default_message
      else
        raise default_message unless is_initial
      end
    end

    def assert_sm_final_state(machine, state, message = nil)
      state_obj = machine.states[state]
      is_final = state_obj&.final?
      default_message = "Expected state #{state} to be final"

      if defined?(::Minitest)
        assert is_final, message || default_message
      elsif defined?(::RSpec)
        expect(is_final).to be_truthy, message || default_message
      else
        raise default_message unless is_final
      end
    end

    def assert_sm_possible_transitions(machine, from:, expected_to_states:, message: nil)
      actual_transitions = machine.events.flat_map do |event|
        event.branches.select { |branch| branch.known_states.include?(from) }
             .map(&:to)
      end.uniq
      default_message = "Expected transitions from #{from} to #{expected_to_states} but got #{actual_transitions}"

      if defined?(::Minitest)
        assert_equal expected_to_states.sort, actual_transitions.sort, message || default_message
      elsif defined?(::RSpec)
        expect(actual_transitions.sort).to eq(expected_to_states.sort), message || default_message
      else
        raise default_message unless expected_to_states.sort == actual_transitions.sort
      end
    end

    def refute_sm_transition_allowed(machine, from:, to:, on:, message: nil)
      event = machine.events[on]
      is_allowed = event&.branches&.any? { |branch| branch.known_states.include?(from) && branch.to == to }
      default_message = "Expected transition from #{from} to #{to} on #{on} to not be allowed"

      if defined?(::Minitest)
        refute is_allowed, message || default_message
      elsif defined?(::RSpec)
        expect(is_allowed).to be_falsy, message || default_message
      elsif is_allowed
        raise default_message
      end
    end
    alias assert_sm_transition_not_allowed refute_sm_transition_allowed

    def assert_sm_event_triggers(object, event, message = nil)
      initial_state = object.state
      object.send("#{event}!")
      state_changed = initial_state != object.state
      default_message = "Expected event #{event} to trigger state change"

      if defined?(::Minitest)
        assert state_changed, message || default_message
      elsif defined?(::RSpec)
        expect(state_changed).to be_truthy, message || default_message
      else
        raise default_message unless state_changed
      end
    end

    def refute_sm_event_triggers(object, event, message = nil)
      initial_state = object.state
      begin
        object.send("#{event}!")
        state_unchanged = initial_state == object.state
        default_message = "Expected event #{event} to not trigger state change"

        if defined?(::Minitest)
          assert state_unchanged, message || default_message
        elsif defined?(::RSpec)
          expect(state_unchanged).to be_truthy, message || default_message
        else
          raise default_message unless state_unchanged
        end
      rescue StateMachines::InvalidTransition
        # Expected behavior - transition was blocked
      end
    end
    alias assert_sm_event_not_triggers refute_sm_event_triggers

    def assert_sm_event_raises_error(object, event, error_class, message = nil)
      default_message = "Expected event #{event} to raise #{error_class}"

      if defined?(::Minitest)
        assert_raises(error_class, message || default_message) do
          object.send("#{event}!")
        end
      elsif defined?(::RSpec)
        expect { object.send("#{event}!") }.to raise_error(error_class), message || default_message
      else
        begin
          object.send("#{event}!")
          raise default_message
        rescue error_class
          # Expected behavior
        end
      end
    end

    def assert_sm_callback_executed(object, callback_name, message = nil)
      callbacks_executed = object.instance_variable_get(:@_sm_callbacks_executed) || []
      callback_was_executed = callbacks_executed.include?(callback_name)
      default_message = "Expected callback #{callback_name} to be executed"

      if defined?(::Minitest)
        assert callback_was_executed, message || default_message
      elsif defined?(::RSpec)
        expect(callback_was_executed).to be_truthy, message || default_message
      else
        raise default_message unless callback_was_executed
      end
    end

    def refute_sm_callback_executed(object, callback_name, message = nil)
      callbacks_executed = object.instance_variable_get(:@_sm_callbacks_executed) || []
      callback_was_executed = callbacks_executed.include?(callback_name)
      default_message = "Expected callback #{callback_name} to not be executed"

      if defined?(::Minitest)
        refute callback_was_executed, message || default_message
      elsif defined?(::RSpec)
        expect(callback_was_executed).to be_falsy, message || default_message
      elsif callback_was_executed
        raise default_message
      end
    end
    alias assert_sm_callback_not_executed refute_sm_callback_executed

    def assert_sm_state_persisted(record, expected:, message: nil)
      record.reload if record.respond_to?(:reload)
      actual_state = record.state
      default_message = "Expected persisted state #{expected} but got #{actual_state}"

      if defined?(::Minitest)
        assert_equal expected, actual_state, message || default_message
      elsif defined?(::RSpec)
        expect(actual_state).to eq(expected), message || default_message
      else
        raise default_message unless expected == actual_state
      end
    end
  end
end
