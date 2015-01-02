require_relative '../../test_helper'

class CallbackWithArgumentsTest < StateMachinesTest
  def setup
    @callback = StateMachines::Callback.new(:before, do: lambda { |*args| @args = args })

    @object = Object.new
    @callback.call(@object, {}, 1, 2, 3)
  end

  def test_should_call_method_with_all_arguments
    assert_equal [@object, 1, 2, 3], @args
  end
end
