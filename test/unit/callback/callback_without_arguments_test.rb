require_relative '../../test_helper'

class CallbackWithoutArgumentsTest < StateMachinesTest
  def setup
    @callback = StateMachines::Callback.new(:before, do: lambda { |object| @arg = object })

    @object = Object.new
    @callback.call(@object, {}, 1, 2, 3)
  end

  def test_should_call_method_with_object_as_argument
    assert_equal @object, @arg
  end
end
