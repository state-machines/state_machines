require_relative '../../test_helper'

class TransitionCollectionWithActionErrorTest < StateMachinesTest
  def setup
    @klass = Class.new do
      def save
        fail ArgumentError
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

    @raised = true
    begin
      @transitions.perform
      @raised = false
    rescue ArgumentError
    end
  end

  def test_should_not_catch_exception
    assert @raised
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

  def test_should_not_run_around_callbacks_after_yield
    assert_equal 0, @around_after_count
  end

  def test_should_not_run_failure_callbacks
    assert_equal 0, @failure_count
  end
end
