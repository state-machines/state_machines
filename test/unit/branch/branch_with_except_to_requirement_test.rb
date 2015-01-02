require_relative '../../test_helper'

class BranchWithExceptToRequirementTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(except_to: :idling)
  end

  def test_should_use_a_blacklist_matcher
    assert_instance_of StateMachines::BlacklistMatcher, @branch.state_requirements.first[:to]
  end

  def test_should_match_if_not_included
    assert @branch.matches?(@object, to: :parked)
  end

  def test_should_not_match_if_included
    refute @branch.matches?(@object, to: :idling)
  end

  def test_should_match_if_nil
    assert @branch.matches?(@object, to: nil)
  end

  def test_should_ignore_from
    assert @branch.matches?(@object, to: :parked, from: :idling)
  end

  def test_should_ignore_on
    assert @branch.matches?(@object, to: :parked, on: :ignite)
  end

  def test_should_be_included_in_known_states
    assert_equal [:idling], @branch.known_states
  end
end
