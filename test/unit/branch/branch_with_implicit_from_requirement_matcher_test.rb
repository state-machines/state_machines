require_relative '../../test_helper'

class BranchWithMultipleFromRequirementsTest < StateMachinesTest
  def setup
    @object = Object.new
    @branch = StateMachines::Branch.new(from: [:idling, :parked])
  end

  def test_should_match_if_included
    assert @branch.matches?(@object, from: :idling)
  end

  def test_should_not_match_if_not_included
    refute @branch.matches?(@object, from: :first_gear)
  end

  def test_should_be_included_in_known_states
    assert_equal [:idling, :parked], @branch.known_states
  end
end
