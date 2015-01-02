require_relative '../../test_helper'

class BranchWithMultipleExceptToRequirementsTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(except_to: [:idling, :parked])
  end

  def test_should_match_if_not_included
    assert @branch.matches?(@object, to: :first_gear)
  end

  def test_should_not_match_if_included
    refute @branch.matches?(@object, to: :idling)
  end

  def test_should_be_included_in_known_states
    assert_equal [:idling, :parked], @branch.known_states
  end
end
