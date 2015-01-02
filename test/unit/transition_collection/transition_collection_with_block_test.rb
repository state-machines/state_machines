require_relative '../../test_helper'

class TransitionCollectionWithBlockTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :actions

      def save
        (@actions ||= []) << :save
      end
    end

    @state = StateMachines::Machine.new(@klass, :state, initial: :parked, action: :save)
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
    @result = @transitions.perform { 1 }
  end

  def test_should_succeed
    assert_equal 1, @result
  end

  def test_should_persist_states
    assert_equal 'idling', @object.state
    assert_equal 'second_gear', @object.status
  end

  def test_should_not_run_machine_actions
    assert_nil @object.actions
  end

  def test_should_use_result_as_transition_result
    assert_equal 1, @state_transition.result
    assert_equal 1, @status_transition.result
  end
end
