require_relative '../../test_helper'

class CallbackWithApplicationTerminatorTest < StateMachinesTest
  def setup
    @original_terminator = StateMachines::Callback.terminator
    StateMachines::Callback.terminator = lambda { |result| result == false }

    @object = Object.new
  end

  def test_should_not_halt_if_terminator_does_not_match
    callback = StateMachines::Callback.new(:before, do: lambda { true })
    callback.call(@object)
  end

  def test_should_halt_if_terminator_matches
    callback = StateMachines::Callback.new(:before, do: lambda { false })
    assert_throws(:halt) { callback.call(@object) }
  end

  def teardown
    StateMachines::Callback.terminator = @original_terminator
  end
end
