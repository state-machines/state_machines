require_relative '../../test_helper'

class CallbackWithMultipleBoundMethodsTest < StateMachinesTest
  def setup
    @object = Object.new

    first_context = nil
    second_context = nil

    @callback = StateMachines::Callback.new(:before, do: [lambda { first_context = self }, lambda { second_context = self }], bind_to_object: true)
    @callback.call(@object)

    @first_context = first_context
    @second_context = second_context
  end

  def test_should_call_each_method_within_the_context_of_the_object
    assert_equal @object, @first_context
    assert_equal @object, @second_context
  end
end
