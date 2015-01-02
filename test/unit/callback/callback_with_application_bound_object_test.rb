require_relative '../../test_helper'

class CallbackWithApplicationBoundObjectTest < StateMachinesTest
  def setup
    @original_bind_to_object = StateMachines::Callback.bind_to_object
    StateMachines::Callback.bind_to_object = true

    context = nil
    @callback = StateMachines::Callback.new(:before, do: lambda { |*_args| context = self })

    @object = Object.new
    @callback.call(@object)
    @context = context
  end

  def test_should_call_method_within_the_context_of_the_object
    assert_equal @object, @context
  end

  def teardown
    StateMachines::Callback.bind_to_object = @original_bind_to_object
  end
end
