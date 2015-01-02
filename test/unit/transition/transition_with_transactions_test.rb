require_relative '../../test_helper'

class TransitionWithTransactionsTest < StateMachinesTest
  def setup
    @klass = Class.new do
      class << self
        attr_accessor :running_transaction
      end

      attr_accessor :result

      def save
        @result = self.class.running_transaction
        true
      end
    end

    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)

    class << @machine
      def within_transaction(object)
        owner_class.running_transaction = object
        yield
        owner_class.running_transaction = false
      end
    end
  end

  def test_should_run_blocks_within_transaction_for_object
    @transition.within_transaction do
      @result = @klass.running_transaction
    end

    assert_equal @object, @result
  end
end
