require_relative '../../test_helper'

class CallbackWithMixedMethodsTest < StateMachinesTest
  def setup
    @callback = StateMachines::Callback.new(:before, :run_argument, do: :run_do) do |object|
      object.callbacks << :block
    end

    class << @object = Object.new
      attr_accessor :callbacks

      def run_argument
        (@callbacks ||= []) << :argument
      end

      def run_do
        (@callbacks ||= []) << :do
      end
    end

    @result = @callback.call(@object)
  end

  def test_should_be_successful
    assert @result
  end

  def test_should_call_each_callback_in_order
    assert_equal [:argument, :do, :block], @object.callbacks
  end
end
