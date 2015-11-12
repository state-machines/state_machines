require_relative '../../test_helper'

class TransitionCollectionWithBeforeCallbackHaltTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_reader :saved

      def save
        @saved = true
      end
    end
    @before_count = 0
    @after_count = 0

    @machine = StateMachines::Machine.new(@klass, initial: :parked, action: :save)
    @machine.state :idling
    @machine.event :ignite

    @machine.before_transition { @before_count += 1; throw :halt }
    @machine.before_transition { @before_count += 1 }
    @machine.after_transition { @after_count += 1 }
    @machine.around_transition { |block| @before_count += 1; block.call; @after_count += 1 }

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

  def test_should_not_run_action
    refute @object.saved
  end

  def test_should_not_run_further_before_callbacks
    assert_equal 1, @before_count
  end

  def test_should_not_run_after_callbacks
    assert_equal 0, @after_count
  end
end
