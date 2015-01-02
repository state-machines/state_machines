require_relative '../../test_helper'

class CallbackWithAroundTypeAndTerminatorTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_not_halt_if_terminator_does_not_match
    callback = StateMachines::Callback.new(:around, do: lambda { |block| block.call(false); false }, terminator: lambda { |result| result == true })
    callback.call(@object)
  end

  def test_should_not_halt_if_terminator_matches
    callback = StateMachines::Callback.new(:around, do: lambda { |block| block.call(false); false }, terminator: lambda { |result| result == false })
    callback.call(@object)
  end
end
