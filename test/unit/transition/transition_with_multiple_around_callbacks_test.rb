require_relative '../../test_helper'

class TransitionWithMultipleAroundCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_before_yield_in_the_order_they_were_defined
    @callbacks = []
    @machine.around_transition { |block| @callbacks << 1; block.call }
    @machine.around_transition { |block| @callbacks << 2; block.call }
    @transition.run_callbacks

    assert_equal [1, 2], @callbacks
  end

  def test_should_before_yield_multiple_methods_in_the_order_they_were_defined
    @callbacks = []
    @machine.around_transition(lambda { |block| @callbacks << 1; block.call }, lambda { |block| @callbacks << 2; block.call })
    @machine.around_transition(lambda { |block| @callbacks << 3; block.call }, lambda { |block| @callbacks << 4; block.call })
    @transition.run_callbacks

    assert_equal [1, 2, 3, 4], @callbacks
  end

  def test_should_after_yield_in_the_reverse_order_they_were_defined
    @callbacks = []
    @machine.around_transition { |block| block.call; @callbacks << 1 }
    @machine.around_transition { |block| block.call; @callbacks << 2 }
    @transition.run_callbacks

    assert_equal [2, 1], @callbacks
  end

  def test_should_after_yield_multiple_methods_in_the_reverse_order_they_were_defined
    @callbacks = []
    @machine.around_transition(lambda { |block| block.call; @callbacks << 1 }) { |block| block.call; @callbacks << 2 }
    @machine.around_transition(lambda { |block| block.call; @callbacks << 3 }) { |block| block.call; @callbacks << 4 }
    @transition.run_callbacks

    assert_equal [4, 3, 2, 1], @callbacks
  end

  def test_should_run_block_between_callback
    @callbacks = []
    @machine.around_transition { |block| @callbacks << :before_1; block.call; @callbacks << :after_1 }
    @machine.around_transition { |block| @callbacks << :before_2; block.call; @callbacks << :after_2 }
    @transition.run_callbacks { @callbacks << :within; { success: true } }

    assert_equal [:before_1, :before_2, :within, :after_2, :after_1], @callbacks
  end

  def test_should_have_access_to_result_after_yield
    @machine.around_transition { |block| @before_result_1 = @transition.result; block.call; @after_result_1 = @transition.result }
    @machine.around_transition { |block| @before_result_2 = @transition.result; block.call; @after_result_2 = @transition.result }
    @transition.run_callbacks { { result: 1, success: true } }

    assert_nil @before_result_1
    assert_nil @before_result_2
    assert_equal 1, @after_result_1
    assert_equal 1, @after_result_2
  end

  def test_should_fail_if_any_before_yield_halted
    @machine.around_transition { |block| block.call }
    @machine.around_transition { throw :halt }

    assert_equal false, @transition.run_callbacks
  end

  def test_should_not_continue_around_callbacks_if_before_yield_halted
    @callbacks = []
    @machine.around_transition { @callbacks << 1; throw :halt }
    @machine.around_transition { |block| @callbacks << 2; block.call; @callbacks << 3 }

    assert_equal false, @transition.run_callbacks
    assert_equal [1], @callbacks
  end

  def test_should_not_continue_around_callbacks_if_later_before_yield_halted
    @callbacks = []
    @machine.around_transition { |block| block.call; @callbacks << 1 }
    @machine.around_transition { throw :halt }

    @transition.run_callbacks
    assert_equal [], @callbacks
  end

  def test_should_not_run_further_callbacks_if_after_yield_halted
    @callbacks = []
    @machine.around_transition { |block| block.call; @callbacks << 1 }
    @machine.around_transition { |block| block.call; throw :halt }

    assert_equal true, @transition.run_callbacks
    assert_equal [], @callbacks
  end

  def test_should_fail_if_any_fail_to_yield
    @callbacks = []
    @machine.around_transition { @callbacks << 1 }
    @machine.around_transition { |block| @callbacks << 2; block.call; @callbacks << 3 }

    assert_equal false, @transition.run_callbacks
    assert_equal [1], @callbacks
  end
end
