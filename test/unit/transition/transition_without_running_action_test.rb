require_relative '../../test_helper'

class TransitionWithoutRunningActionTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :saved

      def save
        @saved = true
      end
    end

    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling
    @machine.event :ignite
    @machine.after_transition { |_object| @run_after = true }

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @result = @transition.perform(false)
  end

  def test_should_have_empty_args
    assert_equal [], @transition.args
  end

  def test_should_not_have_a_result
    assert_nil @transition.result
  end

  def test_should_be_successful
    assert_equal true, @result
  end

  def test_should_change_the_current_state
    assert_equal 'idling', @object.state
  end

  def test_should_not_run_the_action
    refute @object.saved
  end

  def test_should_run_after_callbacks
    assert @run_after
  end
end
