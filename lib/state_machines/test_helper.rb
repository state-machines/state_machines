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
    # @param expected_state [Symbol] The expected state
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the state doesn't match
    #
    # @example
    #   user = User.new
    #   assert_sm_state(user, :active)                              # Uses default :state machine
    #   assert_sm_state(user, :active, machine_name: :status)       # Uses :status machine
    def assert_sm_state(object, expected_state, machine_name: :state, message: nil)
      name_method = "#{machine_name}_name"

      # Handle the case where machine_name doesn't have a corresponding _name method
      unless object.respond_to?(name_method)
        available_machines = begin
          object.class.state_machines.keys
        rescue StandardError
          []
        end
        raise ArgumentError, "No state machine '#{machine_name}' found. Available machines: #{available_machines.inspect}"
      end

      actual = object.send(name_method)
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
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the transition is not available
    #
    # @example
    #   user = User.new
    #   assert_sm_can_transition(user, :activate)                         # Uses default :state machine
    #   assert_sm_can_transition(user, :activate, machine_name: :status)  # Uses :status machine
    def assert_sm_can_transition(object, event, machine_name: :state, message: nil)
      # Try different method naming patterns
      possible_methods = [
        "can_#{event}?",                    # Default state machine or non-namespaced
        "can_#{event}_#{machine_name}?"     # Namespaced events
      ]

      can_method = possible_methods.find { |method| object.respond_to?(method) }

      unless can_method
        available_methods = object.methods.grep(/^can_.*\?$/).sort
        raise ArgumentError, "No transition method found for event :#{event} on machine :#{machine_name}. Available methods: #{available_methods.first(10).inspect}"
      end

      default_message = "Expected to be able to trigger event :#{event} on #{machine_name}, but #{can_method} returned false"

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
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the transition is available
    #
    # @example
    #   user = User.new
    #   assert_sm_cannot_transition(user, :delete)                         # Uses default :state machine
    #   assert_sm_cannot_transition(user, :delete, machine_name: :status)  # Uses :status machine
    def assert_sm_cannot_transition(object, event, machine_name: :state, message: nil)
      # Try different method naming patterns
      possible_methods = [
        "can_#{event}?",                    # Default state machine or non-namespaced
        "can_#{event}_#{machine_name}?"     # Namespaced events
      ]

      can_method = possible_methods.find { |method| object.respond_to?(method) }

      unless can_method
        available_methods = object.methods.grep(/^can_.*\?$/).sort
        raise ArgumentError, "No transition method found for event :#{event} on machine :#{machine_name}. Available methods: #{available_methods.first(10).inspect}"
      end

      default_message = "Expected not to be able to trigger event :#{event} on #{machine_name}, but #{can_method} returned true"

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
    # @param expected_state [Symbol] The expected state after transition
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the transition fails or results in wrong state
    #
    # @example
    #   user = User.new
    #   assert_sm_transition(user, :activate, :active)                           # Uses default :state machine
    #   assert_sm_transition(user, :activate, :active, machine_name: :status)    # Uses :status machine
    def assert_sm_transition(object, event, expected_state, machine_name: :state, message: nil)
      object.send("#{event}!")
      assert_sm_state(object, expected_state, machine_name: machine_name, message: message)
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

    def assert_sm_event_triggers(object, event, machine_name = :state, message = nil)
      initial_state = object.send(machine_name)
      object.send("#{event}!")
      state_changed = initial_state != object.send(machine_name)
      default_message = "Expected event #{event} to trigger state change on #{machine_name}"

      if defined?(::Minitest)
        assert state_changed, message || default_message
      elsif defined?(::RSpec)
        expect(state_changed).to be_truthy, message || default_message
      else
        raise default_message unless state_changed
      end
    end

    def refute_sm_event_triggers(object, event, machine_name = :state, message = nil)
      initial_state = object.send(machine_name)
      begin
        object.send("#{event}!")
        state_unchanged = initial_state == object.send(machine_name)
        default_message = "Expected event #{event} to not trigger state change on #{machine_name}"

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

    # Assert that a record's state is persisted correctly for a specific state machine
    #
    # @param record [Object] The record to check (should respond to reload)
    # @param expected [String, Symbol] The expected persisted state
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the persisted state doesn't match
    #
    # @example
    #   # Default state machine
    #   assert_sm_state_persisted(user, "active")
    #
    #   # Specific state machine
    #   assert_sm_state_persisted(ship, "up", :shields)
    #   assert_sm_state_persisted(ship, "armed", :weapons)
    def assert_sm_state_persisted(record, expected, machine_name = :state, message = nil)
      record.reload if record.respond_to?(:reload)
      actual_state = record.send(machine_name)
      default_message = "Expected persisted state #{expected} for #{machine_name} but got #{actual_state}"

      if defined?(::Minitest)
        assert_equal expected, actual_state, message || default_message
      elsif defined?(::RSpec)
        expect(actual_state).to eq(expected), message || default_message
      else
        raise default_message unless expected == actual_state
      end
    end

    # Assert that executing a block triggers one or more expected events
    #
    # @param object [Object] The object with state machines
    # @param expected_events [Symbol, Array<Symbol>] The event(s) expected to be triggered
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the expected events were not triggered
    #
    # @example
    #   # Single event
    #   assert_sm_triggers_event(vehicle, :crash) { vehicle.redline }
    #
    #   # Multiple events
    #   assert_sm_triggers_event(vehicle, [:crash, :emergency]) { vehicle.emergency_stop }
    #
    #   # Specific machine
    #   assert_sm_triggers_event(vehicle, :disable, machine_name: :alarm) { vehicle.turn_off_alarm }
    def assert_sm_triggers_event(object, expected_events, machine_name: :state, message: nil)
      expected_events = Array(expected_events)
      triggered_events = []

      # Get the state machine
      machine = object.class.state_machines[machine_name]
      raise ArgumentError, "No state machine found for #{machine_name}" unless machine

      # Save original callbacks to restore later
      machine.callbacks[:before].dup

      # Add a temporary callback to track triggered events
      temp_callback = machine.before_transition do |_obj, transition|
        triggered_events << transition.event if transition.event
      end

      begin
        # Execute the block
        yield

        # Check if expected events were triggered
        missing_events = expected_events - triggered_events
        extra_events = triggered_events - expected_events

        unless missing_events.empty? && extra_events.empty?
          default_message = "Expected events #{expected_events.inspect} to be triggered, but got #{triggered_events.inspect}"
          default_message += ". Missing: #{missing_events.inspect}" if missing_events.any?
          default_message += ". Extra: #{extra_events.inspect}" if extra_events.any?

          if defined?(::Minitest)
            assert false, message || default_message
          elsif defined?(::RSpec)
            raise message || default_message
          else
            raise default_message
          end
        end
      ensure
        # Restore original callbacks by removing the temporary one
        machine.callbacks[:before].delete(temp_callback)
      end
    end

    # Assert that a before_transition callback is defined with expected arguments
    #
    # @param machine_or_class [StateMachines::Machine, Class] The machine or class to check
    # @param options [Hash] Expected callback options (on:, from:, to:, do:, if:, unless:)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the callback is not defined
    #
    # @example
    #   # Check for specific transition callback
    #   assert_before_transition(Vehicle, on: :crash, do: :emergency_stop)
    #
    #   # Check with from/to states
    #   assert_before_transition(Vehicle.state_machine, from: :parked, to: :idling, do: :start_engine)
    #
    #   # Check with conditions
    #   assert_before_transition(Vehicle, on: :ignite, if: :seatbelt_on?)
    def assert_before_transition(machine_or_class, options = {}, message = nil)
      _assert_transition_callback(:before, machine_or_class, options, message)
    end

    # Assert that an after_transition callback is defined with expected arguments
    #
    # @param machine_or_class [StateMachines::Machine, Class] The machine or class to check
    # @param options [Hash] Expected callback options (on:, from:, to:, do:, if:, unless:)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the callback is not defined
    #
    # @example
    #   # Check for specific transition callback
    #   assert_after_transition(Vehicle, on: :crash, do: :tow)
    #
    #   # Check with from/to states
    #   assert_after_transition(Vehicle.state_machine, from: :stalled, to: :parked, do: :log_repair)
    def assert_after_transition(machine_or_class, options = {}, message = nil)
      _assert_transition_callback(:after, machine_or_class, options, message)
    end

    # === Sync Mode Assertions ===

    # Assert that a state machine is operating in synchronous mode
    #
    # @param object [Object] The object with state machines
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the machine has async mode enabled
    #
    # @example
    #   user = User.new
    #   assert_sm_sync_mode(user)                           # Uses default :state machine
    #   assert_sm_sync_mode(user, :status)                  # Uses :status machine
    def assert_sm_sync_mode(object, machine_name = :state, message = nil)
      machine = object.class.state_machines[machine_name]
      raise ArgumentError, "No state machine '#{machine_name}' found" unless machine

      async_enabled = machine.respond_to?(:async_mode_enabled?) && machine.async_mode_enabled?
      default_message = "Expected state machine '#{machine_name}' to be in sync mode, but async mode is enabled"

      if defined?(::Minitest)
        refute async_enabled, message || default_message
      elsif defined?(::RSpec)
        expect(async_enabled).to be_falsy, message || default_message
      elsif async_enabled
        raise default_message
      end
    end

    # Assert that async methods are not available on a sync-only object
    #
    # @param object [Object] The object with state machines
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If async methods are available
    #
    # @example
    #   sync_only_car = Car.new  # Car has no async: true machines
    #   assert_sm_no_async_methods(sync_only_car)
    def assert_sm_no_async_methods(object, message = nil)
      async_methods = %i[fire_event_async fire_events_async fire_event_async! async_fire_event]
      available_async_methods = async_methods.select { |method| object.respond_to?(method) }

      default_message = "Expected no async methods to be available, but found: #{available_async_methods.inspect}"

      if defined?(::Minitest)
        assert_empty available_async_methods, message || default_message
      elsif defined?(::RSpec)
        expect(available_async_methods).to be_empty, message || default_message
      elsif available_async_methods.any?
        raise default_message
      end
    end

    # Assert that an object has no async-enabled state machines
    #
    # @param object [Object] The object with state machines
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If any machine has async mode enabled
    #
    # @example
    #   sync_only_vehicle = Vehicle.new  # All machines are sync-only
    #   assert_sm_all_sync(sync_only_vehicle)
    def assert_sm_all_sync(object, message = nil)
      async_machines = []

      object.class.state_machines.each do |name, machine|
        if machine.respond_to?(:async_mode_enabled?) && machine.async_mode_enabled?
          async_machines << name
        end
      end

      default_message = "Expected all state machines to be sync-only, but these have async enabled: #{async_machines.inspect}"

      if defined?(::Minitest)
        assert_empty async_machines, message || default_message
      elsif defined?(::RSpec)
        expect(async_machines).to be_empty, message || default_message
      elsif async_machines.any?
        raise default_message
      end
    end

    # Assert that synchronous event execution works correctly
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event to trigger
    # @param expected_state [Symbol] The expected state after transition
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If sync execution fails
    #
    # @example
    #   car = Car.new
    #   assert_sm_sync_execution(car, :start, :running)
    #   assert_sm_sync_execution(car, :turn_on, :active, :alarm)
    def assert_sm_sync_execution(object, event, expected_state, machine_name = :state, message = nil)
      # Store initial state
      initial_state = object.send(machine_name)

      # Execute event synchronously
      result = object.send("#{event}!")

      # Verify immediate state change (no async delay)
      final_state = object.send(machine_name)

      # Check that transition succeeded
      state_changed = initial_state != final_state
      correct_final_state = final_state.to_s == expected_state.to_s

      default_message = "Expected sync execution of '#{event}' to change #{machine_name} from '#{initial_state}' to '#{expected_state}', but got '#{final_state}'"

      if defined?(::Minitest)
        assert result, "Event #{event} should return true on success"
        assert state_changed, "State should change from #{initial_state}"
        assert correct_final_state, message || default_message
      elsif defined?(::RSpec)
        expect(result).to be_truthy, "Event #{event} should return true on success"
        expect(state_changed).to be_truthy, "State should change from #{initial_state}"
        expect(correct_final_state).to be_truthy, message || default_message
      else
        raise "Event #{event} should return true on success" unless result
        raise "State should change from #{initial_state}" unless state_changed
        raise default_message unless correct_final_state
      end
    end

    # Assert that event execution is immediate (no async delay)
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event to trigger
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If execution appears to be async
    #
    # @example
    #   car = Car.new
    #   assert_sm_immediate_execution(car, :start)
    def assert_sm_immediate_execution(object, event, machine_name = :state, message = nil)
      initial_state = object.send(machine_name)

      # Record start time and execute
      start_time = Time.now
      object.send("#{event}!")
      execution_time = Time.now - start_time

      final_state = object.send(machine_name)
      state_changed = initial_state != final_state

      # Should complete very quickly (under 10ms for sync operations)
      is_immediate = execution_time < 0.01

      default_message = "Expected immediate sync execution of '#{event}', but took #{execution_time}s (likely async)"

      if defined?(::Minitest)
        assert state_changed, "Event should trigger state change"
        assert is_immediate, message || default_message
      elsif defined?(::RSpec)
        expect(state_changed).to be_truthy, "Event should trigger state change"
        expect(is_immediate).to be_truthy, message || default_message
      else
        raise "Event should trigger state change" unless state_changed
        raise default_message unless is_immediate
      end
    end

    # === Async Mode Assertions ===

    # Assert that a state machine is operating in asynchronous mode
    #
    # @param object [Object] The object with state machines
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the machine doesn't have async mode enabled
    #
    # @example
    #   drone = AutonomousDrone.new
    #   assert_sm_async_mode(drone)                         # Uses default :state machine
    #   assert_sm_async_mode(drone, :teleporter_status)     # Uses :teleporter_status machine
    def assert_sm_async_mode(object, machine_name = :state, message = nil)
      machine = object.class.state_machines[machine_name]
      raise ArgumentError, "No state machine '#{machine_name}' found" unless machine

      async_enabled = machine.respond_to?(:async_mode_enabled?) && machine.async_mode_enabled?
      default_message = "Expected state machine '#{machine_name}' to have async mode enabled, but it's in sync mode"

      if defined?(::Minitest)
        assert async_enabled, message || default_message
      elsif defined?(::RSpec)
        expect(async_enabled).to be_truthy, message || default_message
      else
        raise default_message unless async_enabled
      end
    end

    # Assert that async methods are available on an async-enabled object
    #
    # @param object [Object] The object with state machines
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If async methods are not available
    #
    # @example
    #   drone = AutonomousDrone.new  # Has async: true machines
    #   assert_sm_async_methods(drone)
    def assert_sm_async_methods(object, message = nil)
      async_methods = %i[fire_event_async fire_events_async fire_event_async! async_fire_event]
      available_async_methods = async_methods.select { |method| object.respond_to?(method) }

      default_message = "Expected async methods to be available, but found none"

      if defined?(::Minitest)
        refute_empty available_async_methods, message || default_message
      elsif defined?(::RSpec)
        expect(available_async_methods).not_to be_empty, message || default_message
      elsif available_async_methods.empty?
        raise default_message
      end
    end

    # Assert that an object has async-enabled state machines
    #
    # @param object [Object] The object with state machines
    # @param machine_names [Array<Symbol>] Expected async machine names
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If expected machines don't have async mode
    #
    # @example
    #   drone = AutonomousDrone.new
    #   assert_sm_has_async(drone, [:status, :teleporter_status, :shields])
    def assert_sm_has_async(object, machine_names = nil, message = nil)
      if machine_names
        # Check specific machines
        non_async_machines = machine_names.reject do |name|
          machine = object.class.state_machines[name]
          machine&.respond_to?(:async_mode_enabled?) && machine.async_mode_enabled?
        end

        default_message = "Expected machines #{machine_names.inspect} to have async enabled, but these don't: #{non_async_machines.inspect}"

        if defined?(::Minitest)
          assert_empty non_async_machines, message || default_message
        elsif defined?(::RSpec)
          expect(non_async_machines).to be_empty, message || default_message
        elsif non_async_machines.any?
          raise default_message
        end
      else
        # Check that at least one machine has async
        async_machines = object.class.state_machines.select do |name, machine|
          machine.respond_to?(:async_mode_enabled?) && machine.async_mode_enabled?
        end

        default_message = "Expected at least one state machine to have async enabled, but none found"

        if defined?(::Minitest)
          refute_empty async_machines, message || default_message
        elsif defined?(::RSpec)
          expect(async_machines).not_to be_empty, message || default_message
        elsif async_machines.empty?
          raise default_message
        end
      end
    end

    # Assert that individual async event methods are available
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event name
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If async event methods are not available
    #
    # @example
    #   drone = AutonomousDrone.new
    #   assert_sm_async_event_methods(drone, :launch)  # Checks launch_async and launch_async!
    def assert_sm_async_event_methods(object, event, message = nil)
      async_method = "#{event}_async".to_sym
      async_bang_method = "#{event}_async!".to_sym

      has_async = object.respond_to?(async_method)
      has_async_bang = object.respond_to?(async_bang_method)


      if defined?(::Minitest)
        assert has_async, "Missing #{async_method} method"
        assert has_async_bang, "Missing #{async_bang_method} method"
      elsif defined?(::RSpec)
        expect(has_async).to be_truthy, "Missing #{async_method} method"
        expect(has_async_bang).to be_truthy, "Missing #{async_bang_method} method"
      else
        raise "Missing #{async_method} method" unless has_async
        raise "Missing #{async_bang_method} method" unless has_async_bang
      end
    end

    # Assert that an object has thread-safe state methods when async is enabled
    #
    # @param object [Object] The object with state machines
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If thread-safe methods are not available
    #
    # @example
    #   drone = AutonomousDrone.new
    #   assert_sm_thread_safe_methods(drone)
    def assert_sm_thread_safe_methods(object, message = nil)
      thread_safe_methods = %i[state_machine_mutex read_state_safely write_state_safely]
      missing_methods = thread_safe_methods.reject { |method| object.respond_to?(method) }

      default_message = "Expected thread-safe methods to be available, but missing: #{missing_methods.inspect}"

      if defined?(::Minitest)
        assert_empty missing_methods, message || default_message
      elsif defined?(::RSpec)
        expect(missing_methods).to be_empty, message || default_message
      elsif missing_methods.any?
        raise default_message
      end
    end

    # RSpec-style aliases for event triggering (for consistency with RSpec expectations)
    alias expect_to_trigger_event assert_sm_triggers_event
    alias have_triggered_event assert_sm_triggers_event

    private

    # Internal helper for checking transition callbacks
    def _assert_transition_callback(callback_type, machine_or_class, options, message)
      # Get the machine
      machine = machine_or_class.is_a?(StateMachines::Machine) ? machine_or_class : machine_or_class.state_machine
      raise ArgumentError, 'No state machine found' unless machine

      callbacks = machine.callbacks[callback_type] || []

      # Extract expected conditions
      expected_event = options[:on]
      expected_from = options[:from]
      expected_to = options[:to]
      expected_method = options[:do]
      expected_if = options[:if]
      expected_unless = options[:unless]

      # Find matching callback
      matching_callback = callbacks.find do |callback|
        branch = callback.branch

        # Check event requirement
        if expected_event
          event_requirement = branch.event_requirement
          event_matches = if event_requirement && event_requirement.respond_to?(:values)
                            event_requirement.values.include?(expected_event)
                          else
                            false
                          end
          next false unless event_matches
        end

        # Check state requirements (from/to)
        if expected_from || expected_to
          state_matches = false
          branch.state_requirements.each do |req|
            from_matches = !expected_from || (req[:from] && req[:from].respond_to?(:values) && req[:from].values.include?(expected_from))
            to_matches = !expected_to || (req[:to] && req[:to].respond_to?(:values) && req[:to].values.include?(expected_to))

            if from_matches && to_matches
              state_matches = true
              break
            end
          end
          next false unless state_matches
        end

        # Check method requirement
        if expected_method
          methods = callback.instance_variable_get(:@methods) || []
          method_matches = methods.any? do |method|
            (method.is_a?(Symbol) && method == expected_method) ||
              (method.is_a?(String) && method.to_sym == expected_method) ||
              (method.respond_to?(:call) && method.respond_to?(:source_location))
          end
          next false unless method_matches
        end

        # Check if condition
        if expected_if
          if_condition = branch.if_condition
          if_matches = (if_condition.is_a?(Symbol) && if_condition == expected_if) ||
                       (if_condition.is_a?(String) && if_condition.to_sym == expected_if) ||
                       if_condition.respond_to?(:call)
          next false unless if_matches
        end

        # Check unless condition
        if expected_unless
          unless_condition = branch.unless_condition
          unless_matches = (unless_condition.is_a?(Symbol) && unless_condition == expected_unless) ||
                           (unless_condition.is_a?(String) && unless_condition.to_sym == expected_unless) ||
                           unless_condition.respond_to?(:call)
          next false unless unless_matches
        end

        true
      end

      return if matching_callback

      expected_parts = []
      expected_parts << "on: #{expected_event.inspect}" if expected_event
      expected_parts << "from: #{expected_from.inspect}" if expected_from
      expected_parts << "to: #{expected_to.inspect}" if expected_to
      expected_parts << "do: #{expected_method.inspect}" if expected_method
      expected_parts << "if: #{expected_if.inspect}" if expected_if
      expected_parts << "unless: #{expected_unless.inspect}" if expected_unless

      default_message = "Expected #{callback_type}_transition callback with #{expected_parts.join(', ')} to be defined, but it was not found"

      if defined?(::Minitest)
        assert false, message || default_message
      elsif defined?(::RSpec)
        raise message || default_message
      else
        raise default_message
      end
    end
  end
end
