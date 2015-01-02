require_relative '../../test_helper'

class TransitionCollectionWithSkippedActionsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :actions

      def save_state
        (@actions ||= []) << :save_state
        :save_state
      end

      def save_status
        (@actions ||= []) << :save_status
        :save_status
      end
    end

    @callbacks = []

    @state = StateMachines::Machine.new(@klass, initial: :parked, action: :save_state)
    @state.state :idling
    @state.event :ignite
    @state.before_transition { @callbacks << :state_before }
    @state.after_transition { @callbacks << :state_after }
    @state.around_transition { |block| @callbacks << :state_around_before; block.call; @callbacks << :state_around_after }

    @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save_status)
    @status.state :second_gear
    @status.event :shift_up
    @status.before_transition { @callbacks << :status_before }
    @status.after_transition { @callbacks << :status_after }
    @status.around_transition { |block| @callbacks << :status_around_before; block.call; @callbacks << :status_around_after }

    @object = @klass.new

    @transitions = StateMachines::TransitionCollection.new([
      @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
      @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
    ], actions: false)
    @result = @transitions.perform
  end

  def test_should_skip_actions
    assert_equal true, @transitions.skip_actions
  end

  def test_should_succeed
    assert_equal true, @result
  end

  def test_should_persist_states
    assert_equal 'idling', @object.state
    assert_equal 'second_gear', @object.status
  end

  def test_should_not_run_actions
    assert_nil @object.actions
  end

  def test_should_store_results_in_transitions
    assert_nil @state_transition.result
    assert_nil @status_transition.result
  end

  def test_should_run_all_callbacks
    assert_equal [:state_before, :state_around_before, :status_before, :status_around_before, :status_around_after, :status_after, :state_around_after, :state_after], @callbacks
  end
end
