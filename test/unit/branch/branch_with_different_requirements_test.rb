require_relative '../../test_helper'

class BranchWithDifferentRequirementsTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(from: :parked, to: :idling, on: :ignite)
  end

  def test_should_match_empty_query
    assert @branch.matches?(@object)
  end

  def test_should_match_if_all_requirements_match
    assert @branch.matches?(@object, from: :parked, to: :idling, on: :ignite)
  end

  def test_should_not_match_if_from_not_included
    refute @branch.matches?(@object, from: :idling)
  end

  def test_should_not_match_if_to_not_included
    refute @branch.matches?(@object, to: :parked)
  end

  def test_should_not_match_if_on_not_included
    refute @branch.matches?(@object, on: :park)
  end

  def test_should_be_nil_if_unmatched
    assert_nil @branch.match(@object, from: :parked, to: :idling, on: :park)
  end

  def test_should_include_all_known_states
    assert_equal [:parked, :idling], @branch.known_states
  end

  def test_should_not_duplicate_known_statse
    branch = StateMachines::Branch.new(except_from: :idling, to: :idling, on: :ignite)
    assert_equal [:idling], branch.known_states
  end
end
