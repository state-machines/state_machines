# frozen_string_literal: true

require 'test_helper'

class BranchWithMultipleUnlessConditionalsTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_match_if_all_are_false
    branch = StateMachines::Branch.new(unless: [-> { false }, -> { false }])

    assert_match branch, @object
  end

  def test_should_not_match_if_any_are_true
    branch = StateMachines::Branch.new(unless: [-> { true }, -> { false }])

    refute_match branch, @object

    branch = StateMachines::Branch.new(unless: [-> { false }, -> { true }])

    refute_match branch, @object
  end
end
