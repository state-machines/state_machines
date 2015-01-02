require_relative '../../test_helper'

class TransitionCollectionWithCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :saved

      def save
        @saved = true
      end
    end

    @before_callbacks = []
    @after_callbacks = []

    @state = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @state.state :idling
    @state.event :ignite
    @state.before_transition { @before_callbacks << :state_before }
    @state.after_transition { @after_callbacks << :state_after }
    @state.around_transition { |block| @before_callbacks << :state_around; block.call; @after_callbacks << :state_around }

    @status = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save)
    @status.state :second_gear
    @status.event :shift_up
    @status.before_transition { @before_callbacks << :status_before }
    @status.after_transition { @after_callbacks << :status_after }
    @status.around_transition { |block| @before_callbacks << :status_around; block.call; @after_callbacks << :status_around }

    @object = @klass.new
    @transitions = StateMachines::TransitionCollection.new([
      StateMachines::Transition.new(@object, @state, :ignite, :parked, :idling),
      StateMachines::Transition.new(@object, @status, :shift_up, :first_gear, :second_gear)
    ])
  end

  def test_should_run_before_callbacks_in_order
    @transitions.perform
    assert_equal [:state_before, :state_around, :status_before, :status_around], @before_callbacks
  end

  def test_should_halt_if_before_callback_halted_for_first_transition
    @state.before_transition { throw :halt }

    assert_equal false, @transitions.perform
    assert_equal [:state_before, :state_around], @before_callbacks
  end

  def test_should_halt_if_before_callback_halted_for_second_transition
    @status.before_transition { throw :halt }

    assert_equal false, @transitions.perform
    assert_equal [:state_before, :state_around, :status_before, :status_around], @before_callbacks
  end

  def test_should_halt_if_around_callback_halted_before_yield_for_first_transition
    @state.around_transition { throw :halt }

    assert_equal false, @transitions.perform
    assert_equal [:state_before, :state_around], @before_callbacks
  end

  def test_should_halt_if_around_callback_halted_before_yield_for_second_transition
    @status.around_transition { throw :halt }

    assert_equal false, @transitions.perform
    assert_equal [:state_before, :state_around, :status_before, :status_around], @before_callbacks
  end

  def test_should_run_after_callbacks_in_reverse_order
    @transitions.perform
    assert_equal [:status_around, :status_after, :state_around, :state_after], @after_callbacks
  end

  def test_should_not_halt_if_after_callback_halted_for_first_transition
    @state.after_transition { throw :halt }

    assert_equal true, @transitions.perform
    assert_equal [:status_around, :status_after, :state_around, :state_after], @after_callbacks
  end

  def test_should_not_halt_if_around_callback_halted_for_second_transition
    @status.around_transition { |block| block.call; throw :halt }

    assert_equal true, @transitions.perform
    assert_equal [:state_around, :state_after], @after_callbacks
  end

  def test_should_run_before_callbacks_before_persisting_the_state
    @state.before_transition { |object| @before_state = object.state }
    @state.around_transition { |object, _transition, block| @around_state = object.state; block.call }
    @transitions.perform

    assert_equal 'parked', @before_state
    assert_equal 'parked', @around_state
  end

  def test_should_persist_state_before_running_action
    @klass.class_eval do
      attr_reader :saved_on_persist

      def state=(value)
        @state = value
        @saved_on_persist = saved
      end
    end

    @transitions.perform
    refute @object.saved_on_persist
  end

  def test_should_persist_state_before_running_action_block
    @klass.class_eval do
      attr_writer :saved
      attr_reader :saved_on_persist

      def state=(value)
        @state = value
        @saved_on_persist = saved
      end
    end

    @transitions.perform { @object.saved = true }
    refute @object.saved_on_persist
  end

  def test_should_run_after_callbacks_after_running_the_action
    @state.after_transition { |object| @after_saved = object.saved }
    @state.around_transition { |object, _transition, block| block.call; @around_saved = object.saved }
    @transitions.perform

    assert @after_saved
    assert @around_saved
  end
end
