require_relative '../../test_helper'

class TransitionWithBeforeCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_run_before_callbacks
    @machine.before_transition { @run = true }
    result = @transition.run_callbacks

    assert_equal true, result
    assert_equal true, @run
  end

  def test_should_only_run_those_that_match_transition_context
    @count = 0
    callback = lambda { @count += 1 }

    @machine.before_transition from: :parked, to: :idling, on: :park, do: callback
    @machine.before_transition from: :parked, to: :parked, on: :park, do: callback
    @machine.before_transition from: :parked, to: :idling, on: :ignite, do: callback
    @machine.before_transition from: :idling, to: :idling, on: :park, do: callback
    @transition.run_callbacks

    assert_equal 1, @count
  end

  def test_should_pass_transition_as_argument
    @machine.before_transition { |*args| @args = args }
    @transition.run_callbacks

    assert_equal [@object, @transition], @args
  end

  def test_should_catch_halts
    @machine.before_transition { throw :halt }

    result = @transition.run_callbacks
    assert_equal false, result
  end

  def test_should_not_catch_exceptions
    @machine.before_transition { fail ArgumentError }
    assert_raises(ArgumentError) { @transition.run_callbacks }
  end

  def test_should_not_be_able_to_run_twice
    @count = 0
    @machine.before_transition { @count += 1 }
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 1, @count
  end

  def test_should_be_able_to_run_again_after_halt
    @count = 0
    @machine.before_transition { @count += 1; throw :halt }
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 2, @count
  end

  def test_should_be_able_to_run_again_after_resetting
    @count = 0
    @machine.before_transition { @count += 1 }
    @transition.run_callbacks
    @transition.reset
    @transition.run_callbacks
    assert_equal 2, @count
  end

  def test_should_succeed_if_block_result_is_false
    @machine.before_transition { @run = true }
    assert_equal true, @transition.run_callbacks { { result: false } }
    assert @run
  end

  def test_should_succeed_if_block_result_is_true
    @machine.before_transition { @run = true }
    assert_equal true, @transition.run_callbacks { { result: true } }
    assert @run
  end

  def test_should_succeed_if_block_success_is_false
    @machine.before_transition { @run = true }
    assert_equal true, @transition.run_callbacks { { success: false } }
    assert @run
  end

  def test_should_succeed_if_block_success_is_true
    @machine.before_transition { @run = true }
    assert_equal true, @transition.run_callbacks { { success: true } }
    assert @run
  end
end
