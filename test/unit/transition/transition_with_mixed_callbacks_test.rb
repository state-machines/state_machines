require_relative '../../test_helper'

class TransitionWithMixedCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_before_and_around_callbacks_in_order_defined
    @callbacks = []
    @machine.before_transition { @callbacks << :before_1 }
    @machine.around_transition { |block| @callbacks << :around; block.call }
    @machine.before_transition { @callbacks << :before_2 }

    assert_equal true, @transition.run_callbacks
    assert_equal [:before_1, :around, :before_2], @callbacks
  end

  def test_should_run_around_callbacks_before_after_callbacks
    @callbacks = []
    @machine.after_transition { @callbacks << :after_1 }
    @machine.around_transition { |block| block.call; @callbacks << :after_2 }
    @machine.after_transition { @callbacks << :after_3 }

    assert_equal true, @transition.run_callbacks
    assert_equal [:after_2, :after_1, :after_3], @callbacks
  end

  def test_should_have_access_to_result_for_both_after_and_around_callbacks
    @machine.after_transition { @after_result = @transition.result }
    @machine.around_transition { |block| block.call; @around_result = @transition.result }

    @transition.run_callbacks { { result: 1, success: true } }
    assert_equal 1, @after_result
    assert_equal 1, @around_result
  end

  def test_should_not_run_further_callbacks_if_before_callback_halts
    @callbacks = []
    @machine.before_transition { @callbacks << :before_1 }
    @machine.around_transition { |block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1 }
    @machine.before_transition { @callbacks << :before_2; throw :halt }
    @machine.around_transition { |block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2 }
    @machine.after_transition { @callbacks << :after }

    assert_equal false, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1, :before_2], @callbacks
  end

  def test_should_not_run_further_callbacks_if_before_yield_halts
    @callbacks = []
    @machine.before_transition { @callbacks << :before_1 }
    @machine.around_transition { |_block| @callbacks << :before_around_1; throw :halt }
    @machine.before_transition { @callbacks << :before_2; throw :halt }
    @machine.around_transition { |block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2 }
    @machine.after_transition { @callbacks << :after }

    assert_equal false, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1], @callbacks
  end

  def test_should_not_run_further_callbacks_if_around_callback_fails_to_yield
    @callbacks = []
    @machine.before_transition { @callbacks << :before_1 }
    @machine.around_transition { |_block| @callbacks << :before_around_1 }
    @machine.before_transition { @callbacks << :before_2; throw :halt }
    @machine.around_transition { |block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2 }
    @machine.after_transition { @callbacks << :after }

    assert_equal false, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1], @callbacks
  end

  def test_should_not_run_further_callbacks_if_after_yield_halts
    @callbacks = []
    @machine.before_transition { @callbacks << :before_1 }
    @machine.around_transition { |block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1; throw :halt }
    @machine.before_transition { @callbacks << :before_2 }
    @machine.around_transition { |block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2 }
    @machine.after_transition { @callbacks << :after }

    assert_equal true, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1, :before_2, :before_around_2, :after_around_2, :after_around_1], @callbacks
  end

  def test_should_not_run_further_callbacks_if_after_callback_halts
    @callbacks = []
    @machine.before_transition { @callbacks << :before_1 }
    @machine.around_transition { |block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1 }
    @machine.before_transition { @callbacks << :before_2 }
    @machine.around_transition { |block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2 }
    @machine.after_transition { @callbacks << :after_1; throw :halt }
    @machine.after_transition { @callbacks << :after_2 }

    assert_equal true, @transition.run_callbacks
    assert_equal [:before_1, :before_around_1, :before_2, :before_around_2, :after_around_2, :after_around_1, :after_1], @callbacks
  end
end
