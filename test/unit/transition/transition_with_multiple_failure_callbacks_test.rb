require_relative '../../test_helper'

class TransitionWithMultipleFailureCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_run_in_the_order_they_were_defined
    @callbacks = []
    @machine.after_failure { @callbacks << 1 }
    @machine.after_failure { @callbacks << 2 }
    @transition.run_callbacks { { success: false } }

    assert_equal [1, 2], @callbacks
  end

  def test_should_not_run_further_callbacks_if_halted
    @callbacks = []
    @machine.after_failure { @callbacks << 1; throw :halt }
    @machine.after_failure { @callbacks << 2 }

    assert_equal true, @transition.run_callbacks { { success: false } }
    assert_equal [1], @callbacks
  end

  def test_should_fail_if_any_callback_halted
    @machine.after_failure { true }
    @machine.after_failure { throw :halt }

    assert_equal true, @transition.run_callbacks { { success: false } }
  end
end
