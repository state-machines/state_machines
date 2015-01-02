require_relative '../../test_helper'

class CallbackWithUnlessConditionTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_call_if_false
    callback = StateMachines::Callback.new(:before, unless: lambda { false }, do: lambda {})
    assert callback.call(@object)
  end

  def test_should_not_call_if_true
    callback = StateMachines::Callback.new(:before, unless: lambda { true }, do: lambda {})
    refute callback.call(@object)
  end
end
