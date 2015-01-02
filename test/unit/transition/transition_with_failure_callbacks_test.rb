require_relative '../../test_helper'

class TransitionWithFailureCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_only_run_those_that_match_transition_context
    @count = 0
    callback = lambda { @count += 1 }

    @machine.after_failure do: callback
    @machine.after_failure on: :park, do: callback
    @machine.after_failure on: :ignite, do: callback
    @transition.run_callbacks { { success: false } }

    assert_equal 2, @count
  end

  def test_should_run_if_not_successful
    @machine.after_failure { |_object| @run = true }
    @transition.run_callbacks { { success: false } }
    assert @run
  end

  def test_should_not_run_if_successful
    @run = false
    @machine.after_failure { |_object| @run = true }
    @transition.run_callbacks { { success: true } }
    refute @run
  end

  def test_should_pass_transition_as_argument
    @machine.after_failure { |*args| @args = args }

    @transition.run_callbacks { { success: false } }
    assert_equal [@object, @transition], @args
  end

  def test_should_catch_halts
    @machine.after_failure { throw :halt }

    result = @transition.run_callbacks { { success: false } }
    assert_equal true, result
  end

  def test_should_not_catch_exceptions
    @machine.after_failure  { fail ArgumentError }
    assert_raises(ArgumentError) { @transition.run_callbacks { { success: false } } }
  end

  def test_should_not_be_able_to_run_twice
    @count = 0
    @machine.after_failure { @count += 1 }
    @transition.run_callbacks { { success: false } }
    @transition.run_callbacks { { success: false } }
    assert_equal 1, @count
  end

  def test_should_not_be_able_to_run_twice_if_halted
    @count = 0
    @machine.after_failure { @count += 1; throw :halt }
    @transition.run_callbacks { { success: false } }
    @transition.run_callbacks { { success: false } }
    assert_equal 1, @count
  end

  def test_should_be_able_to_run_again_after_resetting
    @count = 0
    @machine.after_failure { @count += 1 }
    @transition.run_callbacks { { success: false } }
    @transition.reset
    @transition.run_callbacks { { success: false } }
    assert_equal 2, @count
  end
end
