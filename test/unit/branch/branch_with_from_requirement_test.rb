require_relative '../../test_helper'

class BranchWithFromRequirementTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(from: :parked)
  end

  def test_should_use_a_whitelist_matcher
    assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:from]
  end

  def test_should_match_if_not_specified
    assert @branch.matches?(@object, to: :idling)
  end

  def test_should_match_if_included
    assert @branch.matches?(@object, from: :parked)
  end

  def test_should_not_match_if_not_included
    refute @branch.matches?(@object, from: :idling)
  end

  def test_should_not_match_if_nil
    refute @branch.matches?(@object, from: nil)
  end

  def test_should_ignore_to
    assert @branch.matches?(@object, from: :parked, to: :idling)
  end

  def test_should_ignore_on
    assert @branch.matches?(@object, from: :parked, on: :ignite)
  end

  def test_should_be_included_in_known_states
    assert_equal [:parked], @branch.known_states
  end

  def test_should_include_requirement_in_match
    match = @branch.match(@object, from: :parked)
    assert_equal @branch.state_requirements.first[:from], match[:from]
  end
end
