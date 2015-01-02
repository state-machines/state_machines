require_relative '../../test_helper'

class CallbackWithUnboundMethodTest < StateMachinesTest
  def setup
    @callback = StateMachines::Callback.new(:before, do: lambda { |*args| @context = args.unshift(self) })

    @object = Object.new
    @callback.call(@object, {}, 1, 2, 3)
  end

  def test_should_call_method_outside_the_context_of_the_object
    assert_equal [self, @object, 1, 2, 3], @context
  end
end
