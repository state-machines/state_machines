require_relative '../../test_helper'

class CallbackWithMultipleDoMethodsTest < StateMachinesTest
  def setup
    @callback = StateMachines::Callback.new(:before, do: [:run_1, :run_2])

    class << @object = Object.new
      attr_accessor :callbacks

      def run_1
        (@callbacks ||= []) << :run_1
      end

      def run_2
        (@callbacks ||= []) << :run_2
      end
    end

    @result = @callback.call(@object)
  end

  def test_should_be_successful
    assert @result
  end

  def test_should_call_each_callback_in_order
    assert_equal [:run_1, :run_2], @object.callbacks
  end
end
