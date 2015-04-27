require_relative '../../test_helper'

class TransitionCollectionWithTransactionsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :running_transaction, :cancelled_transaction
    end

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.state :idling
    @machine.event :ignite

    class << @machine
      def within_transaction(object)
        object.running_transaction = true
        object.cancelled_transaction = yield == false
        object.running_transaction = false
      end
    end

    @object = @klass.new
    @transitions = StateMachines::TransitionCollection.new([
      StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    ], use_transactions: true)
  end

  def test_should_run_before_callbacks_within_transaction
    @machine.before_transition { |object| @in_transaction = object.running_transaction }
    @transitions.perform

    assert @in_transaction
  end

  def test_should_run_action_within_transaction
    @transitions.perform { @in_transaction = @object.running_transaction }

    assert @in_transaction
  end

  def test_should_run_after_callbacks_within_transaction
    @machine.after_transition { |object| @in_transaction = object.running_transaction }
    @transitions.perform

    assert @in_transaction
  end

  def test_should_cancel_the_transaction_on_before_halt
    @machine.before_transition { throw :halt }

    @transitions.perform
    assert @object.cancelled_transaction
  end

  def test_should_cancel_the_transaction_on_action_failure
    @transitions.perform { false }
    assert @object.cancelled_transaction
  end

  def test_should_not_cancel_the_transaction_on_after_halt
    @machine.after_transition { throw :halt }

    @transitions.perform
    refute @object.cancelled_transaction
  end
end
