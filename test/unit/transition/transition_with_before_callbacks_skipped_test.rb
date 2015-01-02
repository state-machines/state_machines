require_relative '../../test_helper'

class TransitionWithBeforeCallbacksSkippedTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_not_run_before_callbacks
    @run = false
    @machine.before_transition { @run = true }

    assert_equal false, @transition.run_callbacks(before: false)
    refute @run
  end

  def test_should_run_failure_callbacks
    @machine.after_failure { @run = true }

    assert_equal false, @transition.run_callbacks(before: false)
    assert @run
  end
end
