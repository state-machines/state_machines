require_relative '../../test_helper'

class TransitionWithAfterCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_run_after_callbacks
    @machine.after_transition { |_object| @run = true }
    result = @transition.run_callbacks

    assert_equal true, result
    assert_equal true, @run
  end

  def test_should_only_run_those_that_match_transition_context
    @count = 0
    callback = lambda { @count += 1 }

    @machine.after_transition from: :parked, to: :idling, on: :park, do: callback
    @machine.after_transition from: :parked, to: :parked, on: :park, do: callback
    @machine.after_transition from: :parked, to: :idling, on: :ignite, do: callback
    @machine.after_transition from: :idling, to: :idling, on: :park, do: callback
    @transition.run_callbacks

    assert_equal 1, @count
  end

  def test_should_not_run_if_not_successful
    @run = false
    @machine.after_transition { |_object| @run = true }
    @transition.run_callbacks { { success: false } }
    refute @run
  end

  def test_should_run_if_successful
    @machine.after_transition { |_object| @run = true }
    @transition.run_callbacks { { success: true } }
    assert @run
  end

  def test_should_pass_transition_as_argument
    @machine.after_transition { |*args| @args = args }

    @transition.run_callbacks
    assert_equal [@object, @transition], @args
  end

  def test_should_catch_halts
    @machine.after_transition { throw :halt }

    result = @transition.run_callbacks
    assert_equal true, result
  end

  def test_should_not_catch_exceptions
    @machine.after_transition  { fail ArgumentError }
    assert_raises(ArgumentError) { @transition.run_callbacks }
  end

  def test_should_not_be_able_to_run_twice
    @count = 0
    @machine.after_transition { @count += 1 }
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 1, @count
  end

  def test_should_not_be_able_to_run_twice_if_halted
    @count = 0
    @machine.after_transition { @count += 1; throw :halt }
    @transition.run_callbacks
    @transition.run_callbacks
    assert_equal 1, @count
  end

  def test_should_be_able_to_run_again_after_resetting
    @count = 0
    @machine.after_transition { @count += 1 }
    @transition.run_callbacks
    @transition.reset
    @transition.run_callbacks
    assert_equal 2, @count
  end
end
