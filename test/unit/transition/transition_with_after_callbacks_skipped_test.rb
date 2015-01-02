require_relative '../../test_helper'

class TransitionWithAfterCallbacksSkippedTest < StateMachinesTest
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

    assert_equal true, @transition.run_callbacks(after: false)
    assert @run
  end

  def test_should_not_run_after_callbacks
    @run = false
    @machine.after_transition { @run = true }

    assert_equal true, @transition.run_callbacks(after: false)
    refute @run
  end

  if StateMachines::Transition.pause_supported?
    def test_should_run_around_callbacks_before_yield
      @machine.around_transition { |block| @run = true; block.call }

      assert_equal true, @transition.run_callbacks(after: false)
      assert @run
    end

    def test_should_not_run_around_callbacks_after_yield
      @run = false
      @machine.around_transition { |block| block.call; @run = true }

      assert_equal true, @transition.run_callbacks(after: false)
      refute @run
    end

    def test_should_continue_around_transition_execution_on_second_call
      @callbacks = []
      @machine.around_transition { |block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1 }
      @machine.around_transition { |block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2 }
      @machine.after_transition { @callbacks << :after }

      assert_equal true, @transition.run_callbacks(after: false)
      assert_equal [:before_around_1, :before_around_2], @callbacks

      assert_equal true, @transition.run_callbacks
      assert_equal [:before_around_1, :before_around_2, :after_around_2, :after_around_1, :after], @callbacks
    end

    def test_should_not_run_further_callbacks_if_halted_during_continue_around_transition
      @callbacks = []
      @machine.around_transition { |block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1 }
      @machine.around_transition { |block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2; throw :halt }
      @machine.after_transition { @callbacks << :after }

      assert_equal true, @transition.run_callbacks(after: false)
      assert_equal [:before_around_1, :before_around_2], @callbacks

      assert_equal true, @transition.run_callbacks
      assert_equal [:before_around_1, :before_around_2, :after_around_2], @callbacks
    end

    def test_should_not_be_able_to_continue_twice
      @count = 0
      @machine.around_transition { |block| block.call; @count += 1 }
      @machine.after_transition { @count += 1 }

      @transition.run_callbacks(after: false)

      2.times do
        assert_equal true, @transition.run_callbacks
        assert_equal 2, @count
      end
    end

    def test_should_not_be_able_to_continue_again_after_halted
      @count = 0
      @machine.around_transition { |block| block.call; @count += 1; throw :halt }
      @machine.after_transition { @count += 1 }

      @transition.run_callbacks(after: false)

      2.times do
        assert_equal true, @transition.run_callbacks
        assert_equal 1, @count
      end
    end

    def test_should_have_access_to_result_after_continued
      @machine.around_transition { |block| @around_before_result = @transition.result; block.call; @around_after_result = @transition.result }
      @machine.after_transition { @after_result = @transition.result }

      @transition.run_callbacks(after: false)
      @transition.run_callbacks { { result: 1 } }

      assert_nil @around_before_result
      assert_equal 1, @around_after_result
      assert_equal 1, @after_result
    end

    def test_should_raise_exceptions_during_around_callbacks_after_yield_in_second_execution
      @machine.around_transition { |block| block.call; fail ArgumentError }

      @transition.run_callbacks(after: false)
      assert_raises(ArgumentError) { @transition.run_callbacks }
    end
  else
    def test_should_raise_exception_on_second_call
      @callbacks = []
      @machine.around_transition { |block| @callbacks << :before_around_1; block.call; @callbacks << :after_around_1 }
      @machine.around_transition { |block| @callbacks << :before_around_2; block.call; @callbacks << :after_around_2 }
      @machine.after_transition { @callbacks << :after }

      assert_raises(ArgumentError) { @transition.run_callbacks(after: false) }
    end
  end
end
