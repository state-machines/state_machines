require_relative '../../test_helper'

class TransitionCollectionValidTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :persisted

      def initialize
        @persisted = nil
        super
        @persisted = []
      end

      def state=(value)
        @persisted << 'state' if @persisted
        @state = value
      end

      def status=(value)
        @persisted << 'status' if @persisted
        @status = value
      end
    end

    @state = StateMachines::Machine.new(@klass, initial: :parked)
    @state.state :idling
    @state.event :ignite
    @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear)
    @status.state :second_gear
    @status.event :shift_up

    @object = @klass.new

    @result = StateMachines::TransitionCollection.new([
      @state_transition = StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
      @status_transition = StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
    ]).perform
  end

  def test_should_succeed
    assert_equal true, @result
  end

  def test_should_persist_each_state
    assert_equal 'idling', @object.state
    assert_equal 'second_gear', @object.status
  end

  def test_should_persist_in_order
    assert_equal %w(state status), @object.persisted
  end

  def test_should_store_results_in_transitions
    assert_nil @state_transition.result
    assert_nil @status_transition.result
  end
end
