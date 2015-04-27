require_relative '../../test_helper'

class TransitionCollectionWithoutTransactionsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :ran_transaction
    end

    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.state :idling
    @machine.event :ignite

    class << @machine
      def within_transaction(object)
        object.ran_transaction = true
      end
    end

    @object = @klass.new
    @transitions = StateMachines::TransitionCollection.new([
      StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    ], use_transactions: false)
    @transitions.perform
  end

  def test_should_not_run_within_transaction
    refute @object.ran_transaction
  end
end
