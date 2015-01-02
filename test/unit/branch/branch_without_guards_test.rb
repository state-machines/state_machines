require_relative '../../test_helper'

class BranchWithoutGuardsTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_match_if_if_is_false
    branch = StateMachines::Branch.new(if: lambda { false })
    assert branch.matches?(@object, guard: false)
  end

  def test_should_match_if_if_is_true
    branch = StateMachines::Branch.new(if: lambda { true })
    assert branch.matches?(@object, guard: false)
  end

  def test_should_match_if_unless_is_false
    branch = StateMachines::Branch.new(unless: lambda { false })
    assert branch.matches?(@object, guard: false)
  end

  def test_should_match_if_unless_is_true
    branch = StateMachines::Branch.new(unless: lambda { true })
    assert branch.matches?(@object, guard: false)
  end
end
