require_relative '../../test_helper'

class BranchWithOnRequirementTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(on: :ignite)
  end

  def test_should_use_a_whitelist_matcher
    assert_instance_of StateMachines::WhitelistMatcher, @branch.event_requirement
  end

  def test_should_match_if_not_specified
    assert @branch.matches?(@object, from: :parked)
  end

  def test_should_match_if_included
    assert @branch.matches?(@object, on: :ignite)
  end

  def test_should_not_match_if_not_included
    refute @branch.matches?(@object, on: :park)
  end

  def test_should_not_match_if_nil
    refute @branch.matches?(@object, on: nil)
  end

  def test_should_ignore_to
    assert @branch.matches?(@object, on: :ignite, to: :parked)
  end

  def test_should_ignore_from
    assert @branch.matches?(@object, on: :ignite, from: :parked)
  end

  def test_should_not_be_included_in_known_states
    assert_equal [], @branch.known_states
  end

  def test_should_include_requirement_in_match
    match = @branch.match(@object, on: :ignite)
    assert_equal @branch.event_requirement, match[:on]
  end
end
