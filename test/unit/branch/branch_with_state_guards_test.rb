# frozen_string_literal: true

require 'test_helper'

class BranchWithStateGuardsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :state1, :state2

      def initialize
        @state1 = 'parked'
        @state2 = 'off'
        super
      end

      state_machine :state1, initial: :parked do
        event :ignite do
          transition parked: :idling
        end
      end

      state_machine :state2, initial: :off do
        event :turn_on do
          transition off: :on
        end
      end

      # A simple method for testing standard :if guards
      def condition_met?
        true
      end
    end

    @object = @klass.new
  end

  # --- :if_state ---
  def test_if_state_allows_transition_when_state_matches
    # Setup: The dependent machine IS in the required state.
    @object.state2 = 'on'

    # Action: Create a branch with an :if_state guard.
    branch = StateMachines::Branch.new(if_state: { state2: :on })

    # Assert: The branch should match.
    assert branch.matches?(@object), "Branch should match when state2 is 'on'"
  end

  def test_if_state_prevents_transition_when_state_does_not_match
    # Setup: The dependent machine is NOT in the required state.
    @object.state2 = 'off'

    # Action: Create a branch with an :if_state guard.
    branch = StateMachines::Branch.new(if_state: { state2: :on })

    # Assert: The branch should NOT match.
    refute branch.matches?(@object), "Branch should not match when state2 is 'off' but 'on' is required"
  end

  # --- :unless_state ---
  def test_unless_state_allows_transition_when_state_does_not_match
    # Setup: The dependent machine is NOT in the guarded state.
    @object.state2 = 'off'

    # Action: Create a branch with an :unless_state guard.
    branch = StateMachines::Branch.new(unless_state: { state2: :on })

    # Assert: The branch should match.
    assert branch.matches?(@object), "Branch should match when state2 is not 'on'"
  end

  def test_unless_state_prevents_transition_when_state_matches
    # Setup: The dependent machine IS in the guarded state.
    @object.state2 = 'on'

    # Action: Create a branch with an :unless_state guard.
    branch = StateMachines::Branch.new(unless_state: { state2: :on })

    # Assert: The branch should NOT match.
    refute branch.matches?(@object), "Branch should not match when state2 is 'on' and that state is guarded against"
  end

  # --- :if_all_states ---
  def test_if_all_states_allows_transition_when_all_states_match
    # Setup: ALL dependent machines are in the required states.
    @object.state1 = 'idling'
    @object.state2 = 'on'

    # Action: Create a branch with :if_all_states.
    branch = StateMachines::Branch.new(if_all_states: { state1: :idling, state2: :on })

    # Assert: The branch should match.
    assert branch.matches?(@object), 'Branch should match when all required states are met'
  end

  def test_if_all_states_prevents_transition_when_one_state_does_not_match
    # Setup: AT LEAST ONE dependent machine is NOT in the required state.
    @object.state1 = 'idling'  # This matches
    @object.state2 = 'off'     # This does NOT match

    # Action: Create a branch with :if_all_states.
    branch = StateMachines::Branch.new(if_all_states: { state1: :idling, state2: :on })

    # Assert: The branch should NOT match.
    refute branch.matches?(@object), 'Branch should not match when not all required states are met'
  end

  # --- :unless_all_states ---
  def test_unless_all_states_allows_transition_when_not_all_states_match
    # Setup: NOT ALL dependent machines are in the specified states.
    @object.state1 = 'idling'  # This matches
    @object.state2 = 'off'     # This does NOT match

    # Action: Create a branch with :unless_all_states.
    branch = StateMachines::Branch.new(unless_all_states: { state1: :idling, state2: :on })

    # Assert: The branch should match.
    assert branch.matches?(@object), 'Branch should match when not all specified states are met'
  end

  def test_unless_all_states_prevents_transition_when_all_states_match
    # Setup: ALL dependent machines are in the specified states.
    @object.state1 = 'idling'
    @object.state2 = 'on'

    # Action: Create a branch with :unless_all_states.
    branch = StateMachines::Branch.new(unless_all_states: { state1: :idling, state2: :on })

    # Assert: The branch should NOT match.
    refute branch.matches?(@object), 'Branch should not match when all specified states are met'
  end

  # --- :if_any_state ---
  def test_if_any_state_allows_transition_when_one_state_matches
    # Setup: AT LEAST ONE dependent machine IS in a required state.
    @object.state1 = 'parked'  # This does NOT match
    @object.state2 = 'on'      # This matches

    # Action: Create a branch with :if_any_state.
    branch = StateMachines::Branch.new(if_any_state: { state1: :idling, state2: :on })

    # Assert: The branch should match.
    assert branch.matches?(@object), 'Branch should match when at least one required state is met'
  end

  def test_if_any_state_prevents_transition_when_no_states_match
    # Setup: NONE of the dependent machines are in the required states.
    @object.state1 = 'parked'  # This does NOT match (needs idling)
    @object.state2 = 'off'     # This does NOT match (needs on)

    # Action: Create a branch with :if_any_state.
    branch = StateMachines::Branch.new(if_any_state: { state1: :idling, state2: :on })

    # Assert: The branch should NOT match.
    refute branch.matches?(@object), 'Branch should not match when no required states are met'
  end

  # --- :unless_any_state ---
  def test_unless_any_state_allows_transition_when_no_states_match
    # Setup: NONE of the dependent machines are in the specified states.
    @object.state1 = 'parked'  # This does NOT match
    @object.state2 = 'off'     # This does NOT match

    # Action: Create a branch with :unless_any_state.
    branch = StateMachines::Branch.new(unless_any_state: { state1: :idling, state2: :on })

    # Assert: The branch should match.
    assert branch.matches?(@object), 'Branch should match when none of the specified states are met'
  end

  def test_unless_any_state_prevents_transition_when_one_state_matches
    # Setup: AT LEAST ONE dependent machine IS in a specified state.
    @object.state1 = 'parked'  # This does NOT match
    @object.state2 = 'on'      # This matches

    # Action: Create a branch with :unless_any_state.
    branch = StateMachines::Branch.new(unless_any_state: { state1: :idling, state2: :on })

    # Assert: The branch should NOT match.
    refute branch.matches?(@object), 'Branch should not match when at least one specified state is met'
  end

  # --- Combination with :if ---
  def test_allows_transition_when_both_if_and_if_state_are_met
    # Setup: The standard :if condition is true AND the :if_state condition is met.
    @object.state2 = 'on'

    # Action: Create a branch with both :if and :if_state guards.
    branch = StateMachines::Branch.new(if: :condition_met?, if_state: { state2: :on })

    # Assert: The branch should match.
    assert branch.matches?(@object), 'Branch should match when both :if and :if_state conditions are met'
  end

  def test_prevents_transition_when_if_is_met_but_if_state_is_not
    # Setup: The standard :if condition is true BUT the :if_state condition is NOT met.
    @object.state2 = 'off' # This does NOT meet the :if_state condition

    # Action: Create a branch with both :if and :if_state guards.
    branch = StateMachines::Branch.new(if: :condition_met?, if_state: { state2: :on })

    # Assert: The branch should NOT match.
    refute branch.matches?(@object), 'Branch should not match when :if is met but :if_state is not'
  end

  def test_prevents_transition_when_if_state_is_met_but_if_is_not
    # Setup: The :if_state condition is met BUT the standard :if condition is false.
    @object.state2 = 'on' # This meets the :if_state condition

    # Action: Create a branch with both :if and :if_state guards where :if returns false.
    branch = StateMachines::Branch.new(if: proc { false }, if_state: { state2: :on })

    # Assert: The branch should NOT match.
    refute branch.matches?(@object), 'Branch should not match when :if_state is met but :if is not'
  end

  # --- Error Handling ---
  def test_raises_error_for_nonexistent_machine
    # Action: Create a branch referencing a machine that doesn't exist.
    branch = StateMachines::Branch.new(if_state: { nonexistent_machine: :some_state })

    # Assert: It should raise an ArgumentError with a specific message.
    error = assert_raises(ArgumentError) do
      branch.matches?(@object)
    end

    assert_match(/State machine 'nonexistent_machine' is not defined/, error.message)
  end

  def test_raises_error_for_nonexistent_state
    # Action: Create a branch referencing a state that doesn't exist on a valid machine.
    branch = StateMachines::Branch.new(if_state: { state1: :nonexistent_state })

    # Assert: It should raise an ArgumentError with a specific message.
    error = assert_raises(ArgumentError) do
      branch.matches?(@object)
    end

    assert_match(/State 'nonexistent_state' is not defined in state machine 'state1'/, error.message)
  end

  # --- Additional Edge Cases ---
  def test_multiple_guard_types_work_together
    # Test that different guard types can be combined successfully
    @object.state1 = 'idling'
    @object.state2 = 'on'

    branch = StateMachines::Branch.new(
      if_state: { state1: :idling },
      unless_state: { state2: :off } # state2 is 'on', so this should pass
    )

    assert branch.matches?(@object), 'Multiple guard types should work together'
  end

  def test_empty_state_guards_always_match
    # Test that when no state guards are specified, the branch matches
    branch = StateMachines::Branch.new({})

    assert branch.matches?(@object), 'Branch with no guards should always match'
  end

  def test_guard_false_bypasses_state_guards
    # Test that when guard: false is specified, state guards are bypassed
    branch = StateMachines::Branch.new(if_state: { nonexistent_machine: :some_state })

    # This should not raise an error because guard: false bypasses the checks
    assert branch.matches?(@object, guard: false), 'guard: false should bypass state guard validation'
  end
end
