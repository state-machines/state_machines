# frozen_string_literal: true

require 'test_helper'

class CallbackWithTerminatorTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_not_halt_if_terminator_does_not_match
    callback = StateMachines::Callback.new(:before, do: -> { false }, terminator: ->(result) { result == true })
    callback.call(@object)
  end

  def test_should_halt_if_terminator_matches
    callback = StateMachines::Callback.new(:before, do: -> { false }, terminator: ->(result) { result == false })
    assert_throws(:halt) { callback.call(@object) }
  end

  def test_should_halt_if_terminator_matches_any_method
    callback = StateMachines::Callback.new(:before, do: [-> { true }, -> { false }], terminator: ->(result) { result == false })
    assert_throws(:halt) { callback.call(@object) }
  end
end
