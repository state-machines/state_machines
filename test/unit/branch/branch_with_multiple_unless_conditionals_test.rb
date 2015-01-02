require_relative '../../test_helper'

class BranchWithMultipleUnlessConditionalsTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_match_if_all_are_false
    branch = StateMachines::Branch.new(unless: [lambda { false }, lambda { false }])
    assert branch.match(@object)
  end

  def test_should_not_match_if_any_are_true
    branch = StateMachines::Branch.new(unless: [lambda { true }, lambda { false }])
    refute branch.match(@object)

    branch = StateMachines::Branch.new(unless: [lambda { false }, lambda { true }])
    refute branch.match(@object)
  end
end
