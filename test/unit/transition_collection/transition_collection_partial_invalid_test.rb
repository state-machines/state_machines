require_relative '../../test_helper'

class TransitionCollectionPartialInvalidTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :ran_transaction
    end

    @callbacks = []

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.state :idling
    @machine.event :ignite
    @machine.before_transition { @callbacks << :before }
    @machine.after_transition { @callbacks << :after }
    @machine.around_transition { |block| @callbacks << :around_before; block.call; @callbacks << :around_after }

    class << @machine
      def within_transaction(object)
        object.ran_transaction = true
      end
    end

    @object = @klass.new

    @transitions = StateMachines::TransitionCollection.new([
      StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling),
      false
    ])
  end

  def test_should_not_store_invalid_values
    assert_equal 1, @transitions.length
  end

  def test_should_not_succeed
    assert_equal false, @transitions.perform
  end

  def test_should_not_start_transaction
    refute @object.ran_transaction
  end

  def test_should_not_run_perform_block
    ran_block = false
    @transitions.perform { ran_block = true }
    refute ran_block
  end

  def test_should_not_run_before_callbacks
    refute @callbacks.include?(:before)
  end

  def test_should_not_persist_states
    assert_equal 'parked', @object.state
  end

  def test_should_not_run_after_callbacks
    refute @callbacks.include?(:after)
  end

  def test_should_not_run_around_callbacks_before_yield
    refute @callbacks.include?(:around_before)
  end

  def test_should_not_run_around_callbacks_after_yield
    refute @callbacks.include?(:around_after)
  end
end
