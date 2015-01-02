require_relative '../../test_helper'

class MachineTest < StateMachinesTest
  def test_should_raise_exception_if_invalid_option_specified
    assert_raises(ArgumentError) { StateMachines::Machine.new(Class.new, invalid: true) }
  end

  def test_should_not_raise_exception_if_custom_messages_specified
    StateMachines::Machine.new(Class.new, messages: { invalid_transition: 'custom' })
  end

  def test_should_evaluate_a_block_during_initialization
    called = true
    StateMachines::Machine.new(Class.new) do
      called = respond_to?(:event)
    end

    assert called
  end

  def test_should_provide_matcher_helpers_during_initialization
    matchers = []

    StateMachines::Machine.new(Class.new) do
      matchers = [all, any, same]
    end

    assert_equal [StateMachines::AllMatcher.instance, StateMachines::AllMatcher.instance, StateMachines::LoopbackMatcher.instance], matchers
  end
end
