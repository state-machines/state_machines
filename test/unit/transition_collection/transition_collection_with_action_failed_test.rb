require_relative '../../test_helper'

class TransitionCollectionWithActionFailedTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def save
        false
      end
    end
    @before_count = 0
    @around_before_count = 0
    @after_count = 0
    @around_after_count = 0
    @failure_count = 0

    @machine = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @machine.state :idling
    @machine.event :ignite

    @machine.before_transition { @before_count += 1 }
    @machine.after_transition { @after_count += 1 }
    @machine.around_transition { |block| @around_before_count += 1; block.call; @around_after_count += 1 }
    @machine.after_failure { @failure_count += 1 }

    @object = @klass.new

    @transitions = StateMachines::TransitionCollection.new([
      StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    ])
    @result = @transitions.perform
  end

  def test_should_not_succeed
    assert_equal false, @result
  end

  def test_should_not_persist_state
    assert_equal 'parked', @object.state
  end

  def test_should_run_before_callbacks
    assert_equal 1, @before_count
  end

  def test_should_run_around_callbacks_before_yield
    assert_equal 1, @around_before_count
  end

  def test_should_not_run_after_callbacks
    assert_equal 0, @after_count
  end

  def test_should_not_run_around_callbacks
    assert_equal 0, @around_after_count
  end

  def test_should_run_failure_callbacks
    assert_equal 1, @failure_count
  end
end
