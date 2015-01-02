require_relative '../../test_helper'

class BranchWithConflictingConditionalsTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_match_if_if_is_true_and_unless_is_false
    branch = StateMachines::Branch.new(if: lambda { true }, unless: lambda { false })
    assert branch.match(@object)
  end

  def test_should_not_match_if_if_is_false_and_unless_is_true
    branch = StateMachines::Branch.new(if: lambda { false }, unless: lambda { true })
    refute branch.match(@object)
  end

  def test_should_not_match_if_if_is_false_and_unless_is_false
    branch = StateMachines::Branch.new(if: lambda { false }, unless: lambda { false })
    refute branch.match(@object)
  end

  def test_should_not_match_if_if_is_true_and_unless_is_true
    branch = StateMachines::Branch.new(if: lambda { true }, unless: lambda { true })
    refute branch.match(@object)
  end
end
