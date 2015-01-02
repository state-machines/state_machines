require_relative '../../test_helper'

class TransitionWithMultipleBeforeCallbacksTest < StateMachinesTest
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
    @machine.before_transition { @callbacks << 1 }
    @machine.before_transition { @callbacks << 2 }
    @transition.run_callbacks

    assert_equal [1, 2], @callbacks
  end

  def test_should_not_run_further_callbacks_if_halted
    @callbacks = []
    @machine.before_transition { @callbacks << 1; throw :halt }
    @machine.before_transition { @callbacks << 2 }

    assert_equal false, @transition.run_callbacks
    assert_equal [1], @callbacks
  end

  def test_should_fail_if_any_callback_halted
    @machine.before_transition { true }
    @machine.before_transition { throw :halt }

    assert_equal false, @transition.run_callbacks
  end
end
