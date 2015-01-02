require_relative '../../test_helper'

class BranchWithToRequirementTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(to: :idling)
  end

  def test_should_use_a_whitelist_matcher
    assert_instance_of StateMachines::WhitelistMatcher, @branch.state_requirements.first[:to]
  end

  def test_should_match_if_not_specified
    assert @branch.matches?(@object, from: :parked)
  end

  def test_should_match_if_included
    assert @branch.matches?(@object, to: :idling)
  end

  def test_should_not_match_if_not_included
    refute @branch.matches?(@object, to: :parked)
  end

  def test_should_not_match_if_nil
    refute @branch.matches?(@object, to: nil)
  end

  def test_should_ignore_from
    assert @branch.matches?(@object, to: :idling, from: :parked)
  end

  def test_should_ignore_on
    assert @branch.matches?(@object, to: :idling, on: :ignite)
  end

  def test_should_be_included_in_known_states
    assert_equal [:idling], @branch.known_states
  end

  def test_should_include_requirement_in_match
    match = @branch.match(@object, to: :idling)
    assert_equal @branch.state_requirements.first[:to], match[:to]
  end
end
