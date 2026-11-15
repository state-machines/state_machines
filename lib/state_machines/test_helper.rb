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

      _sm_assert_equal(expected_state.to_s, actual.to_s, message || default_message)
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
      can_method = _sm_find_can_method(object, event, machine_name)
      default_message = "Expected to be able to trigger event :#{event} on #{machine_name}, but #{can_method} returned false"

      _sm_assert(object.send(can_method), message || default_message)
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
      can_method = _sm_find_can_method(object, event, machine_name)
      default_message = "Expected not to be able to trigger event :#{event} on #{machine_name}, but #{can_method} returned true"

      _sm_refute(object.send(can_method), message || default_message)
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

      _sm_assert_equal(expected_states.sort, actual_states.sort, message || default_message)
    end

    def refute_sm_state_defined(machine, state, message = nil)
      state_exists = machine.states.any? { |s| s.name == state }
      default_message = "Expected state #{state} to not be defined in machine"

      _sm_refute(state_exists, message || default_message)
    end
    alias assert_sm_state_not_defined refute_sm_state_defined

    def assert_sm_initial_state(machine, expected_state, message = nil)
      state_obj = machine.state(expected_state)
      is_initial = state_obj&.initial?
      default_message = "Expected state #{expected_state} to be the initial state"

      _sm_assert(is_initial, message || default_message)
    end

    def assert_sm_final_state(machine, state, message = nil)
      state_obj = machine.states[state]
      is_final = state_obj&.final?
      default_message = "Expected state #{state} to be final"

      _sm_assert(is_final, message || default_message)
    end

    def assert_sm_possible_transitions(machine, from:, expected_to_states:, message: nil)
      actual_transitions = machine.events.flat_map do |event|
        event.branches.select { |branch| branch.known_states.include?(from) }
             .map(&:to)
      end.uniq
      default_message = "Expected transitions from #{from} to #{expected_to_states} but got #{actual_transitions}"

      _sm_assert_equal(expected_to_states.sort, actual_transitions.sort, message || default_message)
    end

    def refute_sm_transition_allowed(machine, from:, to:, on:, message: nil)
      event = machine.events[on]
      is_allowed = event&.branches&.any? { |branch| branch.known_states.include?(from) && branch.to == to }
      default_message = "Expected transition from #{from} to #{to} on #{on} to not be allowed"

      _sm_refute(is_allowed, message || default_message)
    end
    alias assert_sm_transition_not_allowed refute_sm_transition_allowed

    def assert_sm_event_triggers(object, event, machine_name = :state, message = nil)
      initial_state = object.send(machine_name)
      object.send("#{event}!")
      state_changed = initial_state != object.send(machine_name)
      default_message = "Expected event #{event} to trigger state change on #{machine_name}"

      _sm_assert(state_changed, message || default_message)
    end

    def refute_sm_event_triggers(object, event, machine_name = :state, message = nil)
      initial_state = object.send(machine_name)
      begin
        object.send("#{event}!")
        state_unchanged = initial_state == object.send(machine_name)
        default_message = "Expected event #{event} to not trigger state change on #{machine_name}"

        _sm_assert(state_unchanged, message || default_message)
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

      _sm_assert(callback_was_executed, message || default_message)
    end

    def refute_sm_callback_executed(object, callback_name, message = nil)
      callbacks_executed = object.instance_variable_get(:@_sm_callbacks_executed) || []
      callback_was_executed = callbacks_executed.include?(callback_name)
      default_message = "Expected callback #{callback_name} to not be executed"

      _sm_refute(callback_was_executed, message || default_message)
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

      _sm_assert_equal(expected, actual_state, message || default_message)
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

          _sm_flunk(message || default_message)
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

      _sm_refute(async_enabled, message || default_message)
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

      _sm_assert_empty(available_async_methods, message || default_message)
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
        async_machines << name if machine.respond_to?(:async_mode_enabled?) && machine.async_mode_enabled?
      end

      default_message = "Expected all state machines to be sync-only, but these have async enabled: #{async_machines.inspect}"

      _sm_assert_empty(async_machines, message || default_message)
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

      _sm_assert(result, "Event #{event} should return the performed transition on success, but returned #{result.inspect}")
      _sm_assert(state_changed, "State should change from #{initial_state}")
      _sm_assert(correct_final_state, message || default_message)
    end

    # Assert that event execution is immediate: the state has changed when the
    # bang event returns, and it returned no async task to wait on. Decided by
    # what the call did, not by how long it took, so a slow runner (a cold
    # JIT) cannot fail it.
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event to trigger
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the event did not complete synchronously
    #
    # @example
    #   car = Car.new
    #   assert_sm_immediate_execution(car, :start)
    def assert_sm_immediate_execution(object, event, machine_name = :state, message = nil)
      initial_state = object.send(machine_name)
      result = object.send("#{event}!")
      final_state = object.send(machine_name)

      deferred = defined?(::Async::Task) && result.is_a?(::Async::Task)
      default_message = "Expected immediate sync execution of '#{event}', but it returned #{result.class} (async)"

      _sm_assert(initial_state != final_state, message || "Event #{event} should change #{machine_name} before returning")
      _sm_assert(!deferred, message || default_message)
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

      _sm_assert(async_enabled, message || default_message)
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

      default_message = 'Expected async methods to be available, but found none'

      _sm_refute_empty(available_async_methods, message || default_message)
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

        _sm_assert_empty(non_async_machines, message || default_message)
      else
        # Check that at least one machine has async
        async_machines = object.class.state_machines.select do |_name, machine|
          machine.respond_to?(:async_mode_enabled?) && machine.async_mode_enabled?
        end

        default_message = 'Expected at least one state machine to have async enabled, but none found'

        _sm_refute_empty(async_machines, message || default_message)
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
      async_method = :"#{event}_async"
      async_bang_method = :"#{event}_async!"

      has_async = object.respond_to?(async_method)
      has_async_bang = object.respond_to?(async_bang_method)

      _sm_assert(has_async, message || "Missing #{async_method} method")
      _sm_assert(has_async_bang, message || "Missing #{async_bang_method} method")
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

      _sm_assert_empty(missing_methods, message || default_message)
    end

    # === Refusal Reason Assertions ===

    # The reasons an event can be refused for
    #
    # @see StateMachines::Event#refusal
    REFUSAL_REASONS = %i[no_transition guard halted action_failed contended].freeze

    # Assert that firing an event is refused, leaving the machine's state unchanged
    #
    # Fires the non-bang event method, which must return false. When a reason is
    # given, the refusal recorded for the event must equal it.
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event name (plain or namespace-qualified)
    # @param reason [Symbol, nil] The expected refusal reason, or nil to accept any
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [Symbol, nil] The recorded refusal reason
    # @raise [ArgumentError] If the reason is not a known refusal reason
    # @raise [AssertionError] If the event succeeds, changes the state, or is refused for another reason
    #
    # @example
    #   vehicle = Vehicle.new                                         # parked
    #   assert_sm_refused(vehicle, :park)                             # Any reason
    #   assert_sm_refused(vehicle, :park, :no_transition)             # Specific reason
    #   assert_sm_refused(vehicle, :enable, :guard, machine_name: :alarm_state)
    def assert_sm_refused(object, event, reason = nil, machine_name: :state, message: nil)
      _sm_validate_refusal_reason(reason) if reason
      machine, event_obj = _sm_find_event(object, event, machine_name)

      state_before = machine.read(object, :state)
      result = object.public_send(event_obj.qualified_name)
      state_after = machine.read(object, :state)
      actual = event_obj.refusal(object)

      unless result == false
        outcome = result.is_a?(StateMachines::Transition) ? "it transitioned #{result.from_name.inspect} -> #{result.to_name.inspect}" : "it returned #{result.inspect}"
        _sm_flunk(message || "Expected :#{event_obj.qualified_name} on #{machine.name} to be refused, but #{outcome}")
      end
      _sm_assert(state_before == state_after,
                 message || "Expected a refused :#{event_obj.qualified_name} to leave #{machine.name} at #{state_before.inspect}, but it became #{state_after.inspect}")
      if reason
        _sm_assert_equal(reason, actual,
                         message || "Expected :#{event_obj.qualified_name} on #{machine.name} to be refused for #{reason.inspect}, but was refused for #{actual.inspect}")
      end

      actual
    end

    # Assert that the most recent attempt to fire an event was refused for the expected reason
    #
    # Reads the recorded refusal without firing the event.
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event name (plain or namespace-qualified)
    # @param expected_reason [Symbol] The expected refusal reason
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [Symbol] The recorded refusal reason
    # @raise [ArgumentError] If the reason is not a known refusal reason
    # @raise [AssertionError] If the recorded reason differs
    #
    # @example
    #   vehicle.park
    #   assert_sm_refusal(vehicle, :park, :no_transition)
    def assert_sm_refusal(object, event, expected_reason, machine_name: :state, message: nil)
      _sm_validate_refusal_reason(expected_reason)
      machine, event_obj = _sm_find_event(object, event, machine_name)
      actual = event_obj.refusal(object)
      default_message = "Expected the last :#{event_obj.qualified_name} on #{machine.name} to be refused for #{expected_reason.inspect}, but #{actual ? "it was refused for #{actual.inspect}" : 'no refusal was recorded'}"

      _sm_assert_equal(expected_reason, actual, message || default_message)
      actual
    end

    # Assert that the most recent attempt to fire an event recorded no refusal
    #
    # Reads the recorded refusal without firing the event. Passes after a
    # success, or when the event was never fired.
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event name (plain or namespace-qualified)
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If a refusal is recorded
    #
    # @example
    #   vehicle.ignite
    #   refute_sm_refusal(vehicle, :ignite)
    def refute_sm_refusal(object, event, machine_name: :state, message: nil)
      machine, event_obj = _sm_find_event(object, event, machine_name)
      actual = event_obj.refusal(object)
      default_message = "Expected no refusal for the last :#{event_obj.qualified_name} on #{machine.name}, but it was refused for #{actual.inspect}"

      _sm_assert_nil(actual, message || default_message)
    end
    alias assert_sm_no_refusal refute_sm_refusal

    # Assert that the bang event method raises StateMachines::InvalidTransition with the expected reason
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event name (plain or namespace-qualified)
    # @param expected_reason [Symbol] The expected StateMachines::InvalidTransition#reason
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [StateMachines::InvalidTransition] The raised error
    # @raise [ArgumentError] If the reason is not a known refusal reason
    # @raise [AssertionError] If nothing is raised or the reason differs
    #
    # @example
    #   assert_sm_raises_refusal(vehicle, :park, :no_transition)
    def assert_sm_raises_refusal(object, event, expected_reason, machine_name: :state, message: nil)
      _sm_validate_refusal_reason(expected_reason)
      machine, event_obj = _sm_find_event(object, event, machine_name)
      bang = "#{event_obj.qualified_name}!"

      error = _sm_capture_error(StateMachines::InvalidTransition) { object.public_send(bang) }
      _sm_flunk(message || "Expected #{bang} on #{machine.name} to raise StateMachines::InvalidTransition, but nothing was raised") unless error

      _sm_assert_equal(expected_reason, error.reason,
                       message || "Expected #{bang} on #{machine.name} to be refused for #{expected_reason.inspect}, but was refused for #{error.reason.inspect}")
      error
    end

    # Assert that firing events in parallel is refused with the expected reasons
    #
    # +fire_events+ must return false, and +fire_events!+ must raise
    # StateMachines::InvalidParallelTransition whose #reasons equals the
    # expected Hash. Only the events that caused the refusal carry a reason.
    #
    # @param object [Object] The object with state machines
    # @param events [Array<Symbol>] The (qualified) event names to fire together
    # @param expected_reasons [Hash{Symbol => Symbol}] The expected reason per event
    # @param message [String, nil] Custom failure message
    # @return [StateMachines::InvalidParallelTransition] The raised error
    # @raise [ArgumentError] If a reason is not a known refusal reason
    # @raise [AssertionError] If the events are not refused or the reasons differ
    #
    # @example
    #   assert_sm_parallel_refused(vehicle, %i[ignite enable_alarm], { enable_alarm: :no_transition })
    def assert_sm_parallel_refused(object, events, expected_reasons, message: nil)
      raise ArgumentError, "Expected reasons must be a Hash of event => reason, got #{expected_reasons.inspect}" unless expected_reasons.is_a?(Hash)

      expected_reasons.each_value { |reason| _sm_validate_refusal_reason(reason) }
      events = Array(events)

      result = object.fire_events(*events)
      _sm_flunk(message || "Expected fire_events(#{events.map(&:inspect).join(', ')}) to be refused, but it returned #{result.inspect}") unless result == false

      error = _sm_capture_error(StateMachines::InvalidParallelTransition) { object.fire_events!(*events) }
      _sm_flunk(message || "Expected fire_events!(#{events.map(&:inspect).join(', ')}) to raise StateMachines::InvalidParallelTransition, but nothing was raised") unless error

      _sm_assert_equal(expected_reasons, error.reasons,
                       message || "Expected fire_events!(#{events.map(&:inspect).join(', ')}) to be refused for #{expected_reasons.inspect}, but was refused for #{error.reasons.inspect}")
      error
    end

    # RSpec-style aliases for event triggering (for consistency with RSpec expectations)
    alias expect_to_trigger_event assert_sm_triggers_event
    alias have_triggered_event assert_sm_triggers_event

    # RSpec-style aliases for refusal reasons
    alias expect_to_be_refused assert_sm_refused
    alias expect_refusal assert_sm_refusal
    alias expect_no_refusal refute_sm_refusal
    alias expect_to_raise_refusal assert_sm_raises_refusal
    alias expect_parallel_refused assert_sm_parallel_refused

    private

    # Finds the machine and its event, accepting the plain or the
    # namespace-qualified event name, and raising when either is missing
    def _sm_find_event(object, event, machine_name)
      machine = object.class.state_machines[machine_name] if object.class.respond_to?(:state_machines)
      unless machine
        available = object.class.respond_to?(:state_machines) ? object.class.state_machines.keys : []
        raise ArgumentError, "No state machine '#{machine_name}' found. Available machines: #{available.inspect}"
      end

      event_obj = machine.events[event.to_sym] || machine.events[event.to_sym, :qualified_name]
      return [machine, event_obj] if event_obj

      raise ArgumentError, "No event :#{event} found on machine :#{machine_name}. Available events: #{machine.events.map(&:qualified_name).inspect}"
    end

    # Raises a descriptive ArgumentError for an unknown refusal reason, so a
    # typo in the expectation is not reported as a failed refusal
    def _sm_validate_refusal_reason(reason)
      return if REFUSAL_REASONS.include?(reason)

      suggestion = DidYouMean::SpellChecker.new(dictionary: REFUSAL_REASONS).correct(reason.to_s).first if defined?(DidYouMean::SpellChecker)
      hint = suggestion ? " Did you mean #{suggestion.inspect}?" : ''
      raise ArgumentError, "Unknown refusal reason #{reason.inspect}.#{hint} Valid reasons: #{REFUSAL_REASONS.inspect}"
    end

    # Runs the block and returns the error of the given class it raised, or
    # nil when it raised nothing; other errors propagate
    def _sm_capture_error(error_class)
      yield
      nil
    rescue error_class => e
      e
    end

    # Finds the can_<event>? method for the event, trying both the default and
    # namespaced naming patterns, and raising when neither exists
    def _sm_find_can_method(object, event, machine_name)
      possible_methods = [
        "can_#{event}?",                    # Default state machine or non-namespaced
        "can_#{event}_#{machine_name}?"     # Namespaced events
      ]

      can_method = possible_methods.find { |method| object.respond_to?(method) }
      return can_method if can_method

      available_methods = object.methods.grep(/^can_.*\?$/).sort
      raise ArgumentError, "No transition method found for event :#{event} on machine :#{machine_name}. Available methods: #{available_methods.first(10).inspect}"
    end

    # Framework dispatch helpers - route assertions to whichever test
    # framework is loaded (Minitest, RSpec, or none)

    def _sm_assert(condition, message)
      if defined?(::Minitest)
        assert condition, message
      elsif defined?(::RSpec)
        expect(condition).to be_truthy, message
      else
        raise message unless condition
      end
    end

    def _sm_refute(condition, message)
      if defined?(::Minitest)
        refute condition, message
      elsif defined?(::RSpec)
        expect(condition).to be_falsy, message
      elsif condition
        raise message
      end
    end

    def _sm_assert_equal(expected, actual, message)
      if defined?(::Minitest)
        assert_equal expected, actual, message
      elsif defined?(::RSpec)
        expect(actual).to eq(expected), message
      else
        raise message unless expected == actual
      end
    end

    def _sm_assert_nil(value, message)
      if defined?(::Minitest)
        assert_nil value, message
      elsif defined?(::RSpec)
        expect(value).to be_nil, message
      else
        raise message unless value.nil?
      end
    end

    def _sm_assert_empty(collection, message)
      if defined?(::Minitest)
        assert_empty collection, message
      elsif defined?(::RSpec)
        expect(collection).to be_empty, message
      elsif collection.any?
        raise message
      end
    end

    def _sm_refute_empty(collection, message)
      if defined?(::Minitest)
        refute_empty collection, message
      elsif defined?(::RSpec)
        expect(collection).not_to be_empty, message
      elsif collection.empty?
        raise message
      end
    end

    def _sm_flunk(message)
      raise message unless defined?(::Minitest)

      assert false, message
    end

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

      _sm_flunk(message || default_message)
    end
  end
end
