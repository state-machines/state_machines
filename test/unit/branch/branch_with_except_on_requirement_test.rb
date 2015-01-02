require_relative '../../test_helper'

class BranchWithExceptOnRequirementTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(except_on: :ignite)
  end

  def test_should_use_a_blacklist_matcher
    assert_instance_of StateMachines::BlacklistMatcher, @branch.event_requirement
  end

  def test_should_match_if_not_included
    assert @branch.matches?(@object, on: :park)
  end

  def test_should_not_match_if_included
    refute @branch.matches?(@object, on: :ignite)
  end

  def test_should_match_if_nil
    assert @branch.matches?(@object, on: nil)
  end

  def test_should_ignore_to
    assert @branch.matches?(@object, on: :park, to: :idling)
  end

  def test_should_ignore_from
    assert @branch.matches?(@object, on: :park, from: :parked)
  end

  def test_should_not_be_included_in_known_states
    assert_equal [], @branch.known_states
  end
end
