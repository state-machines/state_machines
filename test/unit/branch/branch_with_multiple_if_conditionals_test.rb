# frozen_string_literal: true

require 'test_helper'

class BranchWithMultipleIfConditionalsTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_match_if_all_are_true
    branch = StateMachines::Branch.new(if: [-> { true }, -> { true }])

    assert branch.match(@object)
  end

  def test_should_not_match_if_any_are_false
    branch = StateMachines::Branch.new(if: [-> { true }, -> { false }])

    refute branch.match(@object)

    branch = StateMachines::Branch.new(if: [-> { false }, -> { true }])

    refute branch.match(@object)
  end
end
