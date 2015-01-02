require_relative '../../test_helper'

class CallbackWithBoundMethodAndArgumentsTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_include_single_argument_if_specified
    context = nil
    callback = StateMachines::Callback.new(:before, do: lambda { |arg1| context = [arg1] }, bind_to_object: true)
    callback.call(@object, {}, 1)
    assert_equal [1], context
  end

  def test_should_include_multiple_arguments_if_specified
    context = nil
    callback = StateMachines::Callback.new(:before, do: lambda { |arg1, arg2, arg3| context = [arg1, arg2, arg3] }, bind_to_object: true)
    callback.call(@object, {}, 1, 2, 3)
    assert_equal [1, 2, 3], context
  end

  def test_should_include_arguments_if_splat_used
    context = nil
    callback = StateMachines::Callback.new(:before, do: lambda { |*args| context = args }, bind_to_object: true)
    callback.call(@object, {}, 1, 2, 3)
    assert_equal [1, 2, 3], context
  end
end
