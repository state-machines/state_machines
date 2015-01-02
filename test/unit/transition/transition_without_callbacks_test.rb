require_relative '../../test_helper'

class TransitionWithoutCallbacksTest < StateMachinesTest
  def setup
    @klass = Class.new

    @machine = StateMachines::Machine.new(@klass)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
  end

  def test_should_succeed
    assert_equal true, @transition.run_callbacks
  end

  def test_should_succeed_if_after_callbacks_skipped
    assert_equal true, @transition.run_callbacks(after: false)
  end

  def test_should_call_block_if_provided
    @transition.run_callbacks { @ran_block = true; {} }
    assert @ran_block
  end

  def test_should_track_block_result
    @transition.run_callbacks { { result: 1 } }
    assert_equal 1, @transition.result
  end
end
