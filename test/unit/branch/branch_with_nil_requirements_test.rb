require_relative '../../test_helper'

class BranchWithNilRequirementsTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(from: nil, to: nil)
  end

  def test_should_match_empty_query
    assert @branch.matches?(@object)
  end

  def test_should_match_if_all_requirements_match
    assert @branch.matches?(@object, from: nil, to: nil)
  end

  def test_should_not_match_if_from_not_included
    refute @branch.matches?(@object, from: :parked)
  end

  def test_should_not_match_if_to_not_included
    refute @branch.matches?(@object, to: :idling)
  end

  def test_should_include_all_known_states
    assert_equal [nil], @branch.known_states
  end
end
