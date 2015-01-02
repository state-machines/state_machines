require_relative '../../test_helper'

class BranchWithImplicitRequirementTest < StateMachinesTest
  def setup
    @branch = StateMachines::Branch.new(parked: :idling, on: :ignite)
  end

  def test_should_create_an_event_requirement
    assert_instance_of StateMachines::WhitelistMatcher, @branch.event_requirement
    assert_equal [:ignite], @branch.event_requirement.values
  end

  def test_should_use_a_whitelist_from_matcher
    assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:from]
  end

  def test_should_use_a_whitelist_to_matcher
    assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:to]
  end
end
