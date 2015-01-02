require_relative '../../test_helper'

class TransitionWithAroundCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_run_around_callbacks
    @machine.around_transition { |_object, _transition, block| @run_before = true; block.call; @run_after = true }
    result = @transition.run_callbacks

    assert_equal true, result
    assert_equal true, @run_before
    assert_equal true, @run_after
  end

  def test_should_only_run_those_that_match_transition_context
    @count = 0
    callback = lambda { |_object, _transition, block| @count += 1; block.call }

    @machine.around_transition from: :parked, to: :idling, on: :park, do: callback
    @machine.around_transition from: :parked, to: :parked, on: :park, do: callback
    @machine.around_transition from: :parked, to: :idling, on: :ignite, do: callback
    @machine.around_transition from: :idling, to: :idling, on: :park, do: callback
    @transition.run_callbacks

    assert_equal 1, @count
  end

  def test_should_pass_transition_as_argument
    @machine.around_transition { |*args| block = args.pop; @args = args; block.call }
    @transition.run_callbacks

    assert_equal [@object, @transition], @args
  end

  def test_should_run_block_between_callback
    @callbacks = []
    @machine.around_transition { |block| @callbacks << :before; block.call; @callbacks << :after }
    @transition.run_callbacks { @callbacks << :within; { success: true } }

    assert_equal [:before, :within, :after], @callbacks
  end

  def test_should_have_access_to_result_after_yield
    @machine.around_transition { |block| @before_result = @transition.result; block.call; @after_result = @transition.result }
    @transition.run_callbacks { { result: 1, success: true } }

    assert_nil @before_result
    assert_equal 1, @after_result
  end

  def test_should_catch_before_yield_halts
    @machine.around_transition { throw :halt }

    result = @transition.run_callbacks
    assert_equal false, result
  end

  def test_should_catch_after_yield_halts
    @machine.around_transition { |block| block.call; throw :halt }

    result = @transition.run_callbacks
    assert_equal true, result
  end

  def test_should_not_catch_before_yield
    @machine.around_transition  { fail ArgumentError }
    assert_raises(ArgumentError) { @transition.run_callbacks }
  end

  def test_should_not_catch_after_yield
    @machine.around_transition { |block| block.call; fail ArgumentError }
    assert_raises(ArgumentError) { @transition.run_callbacks }
  end

  def test_should_fail_if_not_yielded
    @machine.around_transition {}

    result = @transition.run_callbacks
    assert_equal false, result
  end

  def test_should_not_be_able_to_run_twice
    @before_count = 0
    @after_count = 0
    @machine.around_transition { |block| @before_count += 1; block.call; @after_count += 1 }
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 1, @before_count
    assert_equal 1, @after_count
  end

  def test_should_be_able_to_run_again_after_resetting
    @before_count = 0
    @after_count = 0
    @machine.around_transition { |block| @before_count += 1; block.call; @after_count += 1 }
    @transition.run_callbacks
    @transition.reset
    @transition.run_callbacks
    assert_equal 2, @before_count
    assert_equal 2, @after_count
  end

  def test_should_succeed_if_block_result_is_false
    @machine.around_transition { |block| @before_run = true; block.call; @after_run = true }
    assert_equal true, @transition.run_callbacks { { success: true, result: false } }
    assert @before_run
    assert @after_run
  end

  def test_should_succeed_if_block_result_is_true
    @machine.around_transition { |block| @before_run = true; block.call; @after_run = true }
    assert_equal true, @transition.run_callbacks { { success: true, result: true } }
    assert @before_run
    assert @after_run
  end

  def test_should_only_run_before_if_block_success_is_false
    @after_run = false
    @machine.around_transition { |block| @before_run = true; block.call; @after_run = true }
    assert_equal true, @transition.run_callbacks { { success: false } }
    assert @before_run
    refute @after_run
  end

  def test_should_succeed_if_block_success_is_false
    @machine.around_transition { |block| @before_run = true; block.call; @after_run = true }
    assert_equal true, @transition.run_callbacks { { success: true } }
    assert @before_run
    assert @after_run
  end
end
