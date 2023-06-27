require 'test_helper'

class BranchWithImplicitToRequirementMatcherTest < StateMachinesTest
  def setup
    @matcher = StateMachines::BlacklistMatcher.new(:idling)
    @branch = StateMachines::Branch.new(parked: @matcher)
  end

  def test_should_convert_from_to_whitelist_matcher
    assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:from]
  end

  def test_should_not_convert_to_to_whitelist_matcher
    assert_equal @matcher, @branch.state_requirements.first[:to]
  end
end
