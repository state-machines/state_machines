require_relative '../../test_helper'

class BranchWithNoRequirementsTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new
  end

  def test_should_use_all_matcher_for_event_requirement
    assert_equal StateMachines::AllMatcher.instance, @branch.event_requirement
  end

  def test_should_use_all_matcher_for_from_state_requirement
    assert_equal StateMachines::AllMatcher.instance, @branch.state_requirements.first[:from]
  end

  def test_should_use_all_matcher_for_to_state_requirement
    assert_equal StateMachines::AllMatcher.instance, @branch.state_requirements.first[:to]
  end

  def test_should_match_empty_query
    assert @branch.matches?(@object, {})
  end

  def test_should_match_non_empty_query
    assert @branch.matches?(@object, to: :idling, from: :parked, on: :ignite)
  end

  def test_should_include_all_requirements_in_match
    match = @branch.match(@object, {})

    assert_equal @branch.state_requirements.first[:from], match[:from]
    assert_equal @branch.state_requirements.first[:to], match[:to]
    assert_equal @branch.event_requirement, match[:on]
  end
end
