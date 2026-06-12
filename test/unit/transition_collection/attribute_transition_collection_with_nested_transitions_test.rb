# frozen_string_literal: true

require 'test_helper'

# Simulates the flow behind state_machines-activerecord issue #91: while one
# machine's attribute transition is running its action, another machine's
# transition is generated mid-action (e.g. the validation cycle picking up an
# event attribute set in a before callback) and stored for deferred completion
# with after: false.  The outer collection must complete that nested
# transition's after callbacks in the same action cycle and clear the stored
# references so they don't leak into the next cycle with stale data.
class AttributeTransitionCollectionWithNestedTransitionsTest < StateMachinesTest
  def setup
    @klass = Class.new

    @state = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @state.state :idling
    @state.event :ignite

    @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save)
    @status.state :second_gear
    @status.event :shift_up

    @after_transitions = []
    @state.after_transition { |_object, transition| @after_transitions << transition }
    @status.after_transition { |_object, transition| @after_transitions << transition }

    @object = @klass.new
    @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling)
    @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)

    @result = StateMachines::AttributeTransitionCollection.new([@state_transition]).perform do
      # Simulates the validation cycle running mid-action and storing the
      # nested transition for deferred completion
      StateMachines::AttributeTransitionCollection.new([@status_transition], after: false).perform { true }
      true
    end
  end

  def test_should_succeed
    assert @result
  end

  def test_should_run_after_callbacks_for_outer_transition
    assert_includes @after_transitions, @state_transition
  end

  def test_should_run_after_callbacks_for_nested_transition_in_same_cycle
    assert_includes @after_transitions, @status_transition
  end

  def test_should_run_outer_after_callbacks_before_nested_ones
    assert_equal [@state_transition, @status_transition], @after_transitions
  end

  def test_should_clear_stored_event_transition
    assert_nil @object.send(:status_event_transition)
  end

  def test_should_clear_stored_transitions_hash
    assert_nil @object.instance_variable_get(:@_state_machine_event_transitions)
  end
end
