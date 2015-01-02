require_relative '../../test_helper'

class BranchWithExceptFromRequirementTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(except_from: :parked)
  end

  def test_should_use_a_blacklist_matcher
    assert_instance_of StateMachines::BlacklistMatcher, @branch.state_requirements.first[:from]
  end

  def test_should_match_if_not_included
    assert @branch.matches?(@object, from: :idling)
  end

  def test_should_not_match_if_included
    refute @branch.matches?(@object, from: :parked)
  end

  def test_should_match_if_nil
    assert @branch.matches?(@object, from: nil)
  end

  def test_should_ignore_to
    assert @branch.matches?(@object, from: :idling, to: :parked)
  end

  def test_should_ignore_on
    assert @branch.matches?(@object, from: :idling, on: :ignite)
  end

  def test_should_be_included_in_known_states
    assert_equal [:parked], @branch.known_states
  end
end
