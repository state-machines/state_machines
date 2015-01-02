require_relative '../../test_helper'

class CallbackWithAroundTypeAndBoundMethodTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_call_method_within_the_context_of_the_object
    context = nil
    callback = StateMachines::Callback.new(:around, do: lambda { |block| context = self; block.call }, bind_to_object: true)
    callback.call(@object, {}, 1, 2, 3)

    assert_equal @object, context
  end

  def test_should_include_arguments_if_specified
    context = nil
    callback = StateMachines::Callback.new(:around, do: lambda { |*args| block = args.pop; context = args; block.call }, bind_to_object: true)
    callback.call(@object, {}, 1, 2, 3)

    assert_equal [1, 2, 3], context
  end
end
