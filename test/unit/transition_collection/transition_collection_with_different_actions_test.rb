require_relative '../../test_helper'

class TransitionCollectionWithDifferentActionsTest < StateMachinesTest
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

    @state = StateMachines::Machine.new(@klass, initial: :parked, action: :save_state)
    @state.state :idling
    @state.event :ignite

    @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save_status)
    @status.state :second_gear
    @status.event :shift_up

    @object = @klass.new

    @transitions = StateMachines::TransitionCollection.new([
      @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
      @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
    ])
  end

  def test_should_succeed
    assert_equal true, @transitions.perform
  end

  def test_should_persist_states
    @transitions.perform
    assert_equal 'idling', @object.state
    assert_equal 'second_gear', @object.status
  end

  def test_should_run_actions_in_order
    @transitions.perform
    assert_equal [:save_state, :save_status], @object.actions
  end

  def test_should_store_results_in_transitions
    @transitions.perform
    assert_equal :save_state, @state_transition.result
    assert_equal :save_status, @status_transition.result
  end

  def test_should_not_halt_if_action_fails_for_first_transition
    @klass.class_eval do
      remove_method :save_state

      def save_state
        (@actions ||= []) << :save_state
        false
      end
    end

    assert_equal false, @transitions.perform
    assert_equal [:save_state, :save_status], @object.actions
  end

  def test_should_halt_if_action_fails_for_second_transition
    @klass.class_eval do
      remove_method :save_status

      def save_status
        (@actions ||= []) << :save_status
        false
      end
    end

    assert_equal false, @transitions.perform
    assert_equal [:save_state, :save_status], @object.actions
  end

  def test_should_rollback_if_action_errors_for_first_transition
    @klass.class_eval do
      remove_method :save_state

      def save_state
        fail ArgumentError
      end
    end

    begin
      ; @transitions.perform
    rescue
    end
    assert_equal 'parked', @object.state
    assert_equal 'first_gear', @object.status
  end

  def test_should_rollback_if_action_errors_for_second_transition
    @klass.class_eval do
      remove_method :save_status

      def save_status
        fail ArgumentError
      end
    end

    begin
      ; @transitions.perform
    rescue
    end
    assert_equal 'parked', @object.state
    assert_equal 'first_gear', @object.status
  end

  def test_should_not_run_after_callbacks_if_action_fails_for_first_transition
    @klass.class_eval do
      remove_method :save_state

      def save_state
        false
      end
    end

    @callbacks = []
    @state.after_transition { @callbacks << :state_after }
    @state.around_transition { |block| block.call; @callbacks << :state_around }
    @status.after_transition { @callbacks << :status_after }
    @status.around_transition { |block| block.call; @callbacks << :status_around }

    @transitions.perform
    assert_equal [], @callbacks
  end

  def test_should_not_run_after_callbacks_if_action_fails_for_second_transition
    @klass.class_eval do
      remove_method :save_status

      def save_status
        false
      end
    end

    @callbacks = []
    @state.after_transition { @callbacks << :state_after }
    @state.around_transition { |block| block.call; @callbacks << :state_around }
    @status.after_transition { @callbacks << :status_after }
    @status.around_transition { |block| block.call; @callbacks << :status_around }

    @transitions.perform
    assert_equal [], @callbacks
  end

  def test_should_run_after_failure_callbacks_if_action_fails_for_first_transition
    @klass.class_eval do
      remove_method :save_state

      def save_state
        false
      end
    end

    @callbacks = []
    @state.after_failure { @callbacks << :state_after }
    @status.after_failure { @callbacks << :status_after }

    @transitions.perform
    assert_equal [:status_after, :state_after], @callbacks
  end

  def test_should_run_after_failure_callbacks_if_action_fails_for_second_transition
    @klass.class_eval do
      remove_method :save_status

      def save_status
        false
      end
    end

    @callbacks = []
    @state.after_failure { @callbacks << :state_after }
    @status.after_failure { @callbacks << :status_after }

    @transitions.perform
    assert_equal [:status_after, :state_after], @callbacks
  end
end
