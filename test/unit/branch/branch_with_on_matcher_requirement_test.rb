require_relative '../../test_helper'

class BranchWithOnMatcherRequirementTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(on: StateMachines::BlacklistMatcher.new([:ignite, :park]))
  end

  def test_should_match_if_included
    assert @branch.matches?(@object, on: :shift_up)
  end

  def test_should_not_match_if_not_included
    refute @branch.matches?(@object, on: :ignite)
  end
end
