require_relative '../../test_helper'

class CallbackByDefaultTest < StateMachinesTest
  def setup
    @callback = StateMachines::Callback.new(:before) {}
  end

  def test_should_have_type
    assert_equal :before, @callback.type
  end

  def test_should_not_have_a_terminator
    assert_nil @callback.terminator
  end

  def test_should_have_a_branch_with_all_matcher_requirements
    assert_equal StateMachines::AllMatcher.instance, @callback.branch.event_requirement
    assert_equal StateMachines::AllMatcher.instance, @callback.branch.state_requirements.first[:from]
    assert_equal StateMachines::AllMatcher.instance, @callback.branch.state_requirements.first[:to]
  end

  def test_should_not_have_any_known_states
    assert_equal [], @callback.known_states
  end
end
