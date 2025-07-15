# frozen_string_literal: true

require 'test_helper'

class BranchWithMultipleIfConditionalsTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_match_if_all_are_true
    branch = StateMachines::Branch.new(if: [-> { true }, -> { true }])

    assert_match branch, @object
  end

  def test_should_not_match_if_any_are_false
    branch = StateMachines::Branch.new(if: [-> { true }, -> { false }])

    refute_match branch, @object

    branch = StateMachines::Branch.new(if: [-> { false }, -> { true }])

    refute_match branch, @object
  end
end
