require_relative '../../test_helper'

class CallbackWithoutTerminatorTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_not_halt_if_result_is_false
    callback = StateMachines::Callback.new(:before, do: lambda { false }, terminator: nil)
    callback.call(@object)
  end
end
