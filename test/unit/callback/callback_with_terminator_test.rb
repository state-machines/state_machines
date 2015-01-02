require_relative '../../test_helper'

class CallbackWithTerminatorTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_not_halt_if_terminator_does_not_match
    callback = StateMachines::Callback.new(:before, do: lambda { false }, terminator: lambda { |result| result == true })
    callback.call(@object)
  end

  def test_should_halt_if_terminator_matches
    callback = StateMachines::Callback.new(:before, do: lambda { false }, terminator: lambda { |result| result == false })
    assert_throws(:halt) { callback.call(@object) }
  end

  def test_should_halt_if_terminator_matches_any_method
    callback = StateMachines::Callback.new(:before, do: [lambda { true }, lambda { false }], terminator: lambda { |result| result == false })
    assert_throws(:halt) { callback.call(@object) }
  end
end
