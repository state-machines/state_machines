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
      default_message = "Expected #{object.class}##{machine_name} to be #{expected_state.inspect}, but was #{actual.inspect}"

      _sm_assert(_sm_same_state?(expected_state, actual), message || default_message)
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

    # Assert the machine's states, in any order. Names resolve through the
    # machine ('parked' is :parked). The nil state is only listed when expected,
    # since a machine without an initial state has one implicitly.
    def assert_sm_states_list(machine, expected_states, message = nil)
      expected = expected_states.map { |state| machine.states[state]&.name || state }
      actual = machine.states.map(&:name)
      actual.compact! unless expected_states.include?(nil)
      default_message = "Expected states #{expected.inspect} but got #{actual.inspect}"

      _sm_assert_equal(expected.sort_by(&:inspect), actual.sort_by(&:inspect), message || default_message)
    end

    def refute_sm_state_defined(machine, state, message = nil)
      default_message = "Expected state #{state.inspect} to not be defined in machine"

      _sm_refute(machine.states[state], message || default_message)
    end
    alias assert_sm_state_not_defined refute_sm_state_defined

    # @raise [IndexError] if +expected_state+ is not a known state
    def assert_sm_initial_state(machine, expected_state, message = nil)
      state = machine.states.fetch(expected_state)
      default_message = "Expected state #{state.name.inspect} to be the initial state"

      _sm_assert(state.initial?, message || default_message)
    end

    # @raise [IndexError] if +state+ is not a known state
    def assert_sm_final_state(machine, state, message = nil)
      state = machine.states.fetch(state)
      default_message = "Expected state #{state.name.inspect} to be final"

      _sm_assert(state.final?, message || default_message)
    end

    # Assert the set of states the machine's events can lead to from a state,
    # ignoring guards. Each branch contributes the target it would pick for
    # +from+ (a loopback contributes +from+ itself); order does not matter.
    #
    # @param machine [StateMachines::Machine] The state machine
    # @param from [Symbol, String, nil] The source state
    # @param expected_to_states [Array] The expected target states
    # @param message [String, nil] Custom failure message
    # @raise [IndexError] if +from+ or an expected state is not a known state
    def assert_sm_possible_transitions(machine, from:, expected_to_states:, message: nil)
      from = machine.states.fetch(from).name
      names = machine.states.map(&:name)
      expected = expected_to_states.map { |state| machine.states.fetch(state).name }.uniq
      actual = machine.events.flat_map do |event|
        event.branches.flat_map { |branch| _sm_branch_targets(branch, from, names) }
      end.uniq
      by_definition = ->(name) { names.index(name) }
      default_message = "Expected transitions from #{from.inspect} to #{expected.inspect} but got #{actual.inspect}"

      _sm_assert_equal(expected.sort_by(&by_definition), actual.sort_by(&by_definition), message || default_message)
    end

    # Refute that an event has a branch from +from+ to +to+, ignoring guards.
    #
    # @raise [IndexError] if +on+, +from+ or +to+ is unknown
    def refute_sm_transition_allowed(machine, from:, to:, on:, message: nil)
      event = machine.events.fetch(on)
      from = machine.states.fetch(from).name
      to = machine.states.fetch(to).name
      names = machine.states.map(&:name)
      is_allowed = event.branches.any? { |branch| _sm_branch_targets(branch, from, names) == [to] }
      default_message = "Expected transition from #{from.inspect} to #{to.inspect} on #{event.name.inspect} to not be allowed"

      _sm_refute(is_allowed, message || default_message)
    end
    alias assert_sm_transition_not_allowed refute_sm_transition_allowed

    def assert_sm_event_triggers(object, event, machine_name = :state, message = nil)
      machine = object.class.state_machine(machine_name)
      initial_state = machine.read(object, :state)
      object.send("#{event}!")
      state_changed = initial_state != machine.read(object, :state)
      default_message = "Expected event #{event} to trigger state change on #{machine_name}"

      _sm_assert(state_changed, message || default_message)
    end

    def refute_sm_event_triggers(object, event, machine_name = :state, message = nil)
      machine = object.class.state_machine(machine_name)
      initial_state = machine.read(object, :state)
      begin
        object.send("#{event}!")
        state_unchanged = initial_state == machine.read(object, :state)
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
      triggered_events = []

      # Get the state machine
      machine = object.class.state_machines[machine_name]
      raise ArgumentError, "No state machine found for #{machine_name}" unless machine

      # Resolve the names ('crash' is :crash); an unknown event raises IndexError
      expected_events = Array(expected_events).map { |event| machine.events.fetch(event).name }

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

    # === Execution Assertions ===

    # Assert that firing a bang event transitions to the expected state
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

      # Verify the state changed by the time the event returned
      final_state = object.send(machine_name)

      # Check that transition succeeded
      state_changed = initial_state != final_state
      correct_final_state = _sm_same_state?(expected_state, final_state)

      default_message = "Expected sync execution of '#{event}' to change #{machine_name} from '#{initial_state}' to '#{expected_state}', but got '#{final_state}'"

      _sm_assert(result, "Event #{event} should return the performed transition on success, but returned #{result.inspect}")
      _sm_assert(state_changed, "State should change from #{initial_state}")
      _sm_assert(correct_final_state, message || default_message)
    end

    # Assert that event execution is immediate: the state has changed when the
    # bang event returns, and it returned the performed transition rather than
    # something to wait on. Decided by what the call did, not by how long it
    # took, so a slow runner (a cold JIT) cannot fail it.
    #
    # @param object [Object] The object with state machines
    # @param event [Symbol] The event to trigger
    # @param machine_name [Symbol] The name of the state machine (defaults to :state)
    # @param message [String, nil] Custom failure message
    # @return [void]
    # @raise [AssertionError] If the event did not complete before returning
    #
    # @example
    #   car = Car.new
    #   assert_sm_immediate_execution(car, :start)
    def assert_sm_immediate_execution(object, event, machine_name = :state, message = nil)
      initial_state = object.send(machine_name)
      result = object.send("#{event}!")
      final_state = object.send(machine_name)

      default_message = "Expected immediate execution of '#{event}' to return the performed transition, but it returned #{result.class}"

      _sm_assert(initial_state != final_state, message || "Event #{event} should change #{machine_name} before returning")
      _sm_assert(result.is_a?(StateMachines::Transition), message || default_message)
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

    # Compares a state name or value with an expected state, treating a
    # String and its Symbol as equal.  nil only equals nil: comparing by to_s
    # alone would make the nil state and a state named :"" indistinguishable.
    def _sm_same_state?(expected, actual)
      expected.nil? || actual.nil? ? expected.nil? && actual.nil? : expected.to_s == actual.to_s
    end

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

    # The target a branch would pick from +from+ (as Event#transition_for
    # does, ignoring guards), as [] or [target]. first(1), not first: a
    # transition into the nil state must not read as none.
    def _sm_branch_targets(branch, from, names)
      requirement = branch.state_requirements.detect { |candidate| candidate[:from].matches?(from) }
      return [] unless requirement

      requirement[:to].is_a?(LoopbackMatcher) ? [from] : requirement[:to].filter([from] | names).first(1)
    end

    # Whether a callback's from/to requirement admits the expected states. A
    # loopback (same) lands where it left, so without an expected source the
    # source is the target itself.
    def _sm_state_requirement_matches?(requirement, states)
      loopback = requirement[:to].is_a?(LoopbackMatcher)
      from = states.key?(:from) ? states[:from] : states[:to]
      return false if (states.key?(:from) || loopback) && !requirement[:from].matches?(from)

      !states.key?(:to) || requirement[:to].matches?(states[:to], from: from)
    end

    # Whether every expected callable (one or an Array) is among the defined
    # ones. Method names compare as String/Symbol alike; anything else, such as
    # a lambda, only matches itself.
    def _sm_includes_callables?(defined, expected)
      defined = Array(defined)
      name = ->(value) { value.is_a?(Symbol) || value.is_a?(String) }
      Array(expected).all? do |wanted|
        defined.any? do |candidate|
          name.call(candidate) && name.call(wanted) ? candidate.to_s == wanted.to_s : candidate.equal?(wanted)
        end
      end
    end

    # Internal helper for checking transition callbacks
    def _assert_transition_callback(callback_type, machine_or_class, options, message)
      # Get the machine
      machine = machine_or_class.is_a?(StateMachines::Machine) ? machine_or_class : machine_or_class.state_machine
      raise ArgumentError, 'No state machine found' unless machine

      callbacks = machine.callbacks[callback_type] || []

      # Extract expected conditions. States and events resolve to their
      # canonical names first, since the branch matchers compare those: a raw
      # 'parked' would never equal :parked, and would pass any all - :parked.
      # An unknown name raises IndexError.
      expected_event = machine.events.fetch(options[:on]).name if options.key?(:on)
      states = options.slice(:from, :to).transform_values { |state| machine.states.fetch(state).name }
      expected_from = states[:from]
      expected_to = states[:to]
      expected_method = options[:do]
      expected_if = options[:if]
      expected_unless = options[:unless]

      # Find matching callback. Requirements are checked with the matchers'
      # own matches?, so all / all - [...] / same behave as they do at runtime,
      # and an expected nil state is an expectation, not an omission.
      matching_callback = callbacks.find do |callback|
        branch = callback.branch

        next false if options.key?(:on) && !branch.event_requirement.matches?(expected_event)
        next false if states.any? &&
                      branch.state_requirements.none? { |requirement| _sm_state_requirement_matches?(requirement, states) }
        next false if options.key?(:do) && !_sm_includes_callables?(callback.instance_variable_get(:@methods), expected_method)
        next false if options.key?(:if) && !_sm_includes_callables?(branch.if_condition, expected_if)
        next false if options.key?(:unless) && !_sm_includes_callables?(branch.unless_condition, expected_unless)

        true
      end

      return if matching_callback

      expected_parts = []
      expected_parts << "on: #{expected_event.inspect}" if options.key?(:on)
      expected_parts << "from: #{expected_from.inspect}" if options.key?(:from)
      expected_parts << "to: #{expected_to.inspect}" if options.key?(:to)
      expected_parts << "do: #{expected_method.inspect}" if options.key?(:do)
      expected_parts << "if: #{expected_if.inspect}" if options.key?(:if)
      expected_parts << "unless: #{expected_unless.inspect}" if options.key?(:unless)

      default_message = "Expected #{callback_type}_transition callback with #{expected_parts.join(', ')} to be defined, but it was not found"

      _sm_flunk(message || default_message)
    end
  end
end
