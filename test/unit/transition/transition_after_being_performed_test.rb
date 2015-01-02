require_relative '../../test_helper'

class TransitionAfterBeingPerformedTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :saved, :save_state

      def save
        @save_state = state
        @saved = true
        1
      end
    end

    @machine = StateMachines::Machine.new(@klass, action: :save)
    @machine.state :parked, :idling
    @machine.event :ignite

    @object = @klass.new
    @object.state = 'parked'
    @transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @result = @transition.perform
  end

  def test_should_have_empty_args
    assert_equal [], @transition.args
  end

  def test_should_have_a_result
    assert_equal 1, @transition.result
  end

  def test_should_be_successful
    assert_equal true, @result
  end

  def test_should_change_the_current_state
    assert_equal 'idling', @object.state
  end

  def test_should_run_the_action
    assert @object.saved
  end

  def test_should_run_the_action_after_saving_the_state
    assert_equal 'idling', @object.save_state
  end
end
