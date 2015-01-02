require_relative '../../test_helper'

class BranchWithMultipleExceptOnRequirementsTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(except_on: [:ignite, :park])
  end

  def test_should_match_if_not_included
    assert @branch.matches?(@object, on: :shift_up)
  end

  def test_should_not_match_if_included
    refute @branch.matches?(@object, on: :ignite)
  end
end
