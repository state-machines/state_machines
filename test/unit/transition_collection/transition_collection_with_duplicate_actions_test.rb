require_relative '../../test_helper'

class TransitionCollectionWithDuplicateActionsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :actions

      def save
        (@actions ||= []) << :save
        :save
      end
    end

    @state = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @state.state :idling
    @state.event :ignite

    @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save)
    @status.state :second_gear
    @status.event :shift_up

    @object = @klass.new

    @transitions = StateMachines::TransitionCollection.new([
      @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
      @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
    ])
    @result = @transitions.perform
  end

  def test_should_succeed
    assert_equal :save, @result
  end

  def test_should_persist_states
    assert_equal 'idling', @object.state
    assert_equal 'second_gear', @object.status
  end

  def test_should_run_action_once
    assert_equal [:save], @object.actions
  end

  def test_should_store_results_in_transitions
    assert_equal :save, @state_transition.result
    assert_equal :save, @status_transition.result
  end
end
