require_relative '../../test_helper'

class CallbackWithBoundMethodTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_call_method_within_the_context_of_the_object_for_block_methods
    context = nil
    callback = StateMachines::Callback.new(:before, do: lambda { |*args| context = [self] + args }, bind_to_object: true)
    callback.call(@object, {}, 1, 2, 3)

    assert_equal [@object, 1, 2, 3], context
  end

  def test_should_ignore_option_for_symbolic_methods
    class << @object
      attr_reader :context

      def after_ignite(*args)
        @context = args
      end
    end

    callback = StateMachines::Callback.new(:before, do: :after_ignite, bind_to_object: true)
    callback.call(@object)

    assert_equal [], @object.context
  end

  def test_should_ignore_option_for_string_methods
    callback = StateMachines::Callback.new(:before, do: '[1, 2, 3]', bind_to_object: true)
    assert callback.call(@object)
  end
end
