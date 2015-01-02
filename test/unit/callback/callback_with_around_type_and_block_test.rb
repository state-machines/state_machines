require_relative '../../test_helper'

class CallbackWithAroundTypeAndBlockTest < StateMachinesTest
  def setup
    @object = Object.new
    @callbacks = []
  end

  def test_should_evaluate_before_without_after
    callback = StateMachines::Callback.new(:around, lambda { |*args| block = args.pop; @args = args; block.call })
    assert callback.call(@object)
    assert_equal [@object], @args
  end

  def test_should_evaluate_after_without_before
    callback = StateMachines::Callback.new(:around, lambda { |*args| block = args.pop; block.call; @args = args })
    assert callback.call(@object)
    assert_equal [@object], @args
  end

  def test_should_halt_if_not_yielded
    callback = StateMachines::Callback.new(:around, lambda { |_block| })
    assert_throws(:halt) { callback.call(@object) }
  end

  def test_should_call_block_after_before
    callback = StateMachines::Callback.new(:around, lambda { |block| @callbacks << :before; block.call })
    assert callback.call(@object) { @callbacks << :block }
    assert_equal [:before, :block], @callbacks
  end

  def test_should_call_block_before_after
    @callbacks = []
    callback = StateMachines::Callback.new(:around, lambda { |block| block.call; @callbacks << :after })
    assert callback.call(@object) { @callbacks << :block }
    assert_equal [:block, :after], @callbacks
  end

  def test_should_halt_if_block_halts
    callback = StateMachines::Callback.new(:around, lambda { |block| block.call; @callbacks << :after })
    assert_throws(:halt) { callback.call(@object) { throw :halt }  }
    assert_equal [], @callbacks
  end
end
