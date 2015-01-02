require_relative '../../test_helper'

class CallbackWithAroundTypeAndArgumentsTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_include_object_if_specified
    callback = StateMachines::Callback.new(:around, lambda { |object, block| @args = [object]; block.call })
    callback.call(@object)
    assert_equal [@object], @args
  end

  def test_should_include_arguments_if_specified
    callback = StateMachines::Callback.new(:around, lambda { |object, arg1, arg2, arg3, block| @args = [object, arg1, arg2, arg3]; block.call })
    callback.call(@object, {}, 1, 2, 3)
    assert_equal [@object, 1, 2, 3], @args
  end

  def test_should_include_arguments_if_splat_used
    callback = StateMachines::Callback.new(:around, lambda { |*args| block = args.pop; @args = args; block.call })
    callback.call(@object, {}, 1, 2, 3)
    assert_equal [@object, 1, 2, 3], @args
  end
end
