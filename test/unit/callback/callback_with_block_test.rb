require_relative '../../test_helper'

class CallbackWithBlockTest < StateMachinesTest
  def setup
    @callback = StateMachines::Callback.new(:before) do |*args|
      @args = args
    end

    @object = Object.new
    @result = @callback.call(@object)
  end

  def test_should_be_successful
    assert @result
  end

  def test_should_call_with_empty_context
    assert_equal [@object], @args
  end
end
