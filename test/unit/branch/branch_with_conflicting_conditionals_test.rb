# frozen_string_literal: true

require 'test_helper'

class BranchWithConflictingConditionalsTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_match_if_if_is_true_and_unless_is_false
    branch = StateMachines::Branch.new(if: -> { true }, unless: -> { false })

    assert_match branch, @object
  end

  def test_should_not_match_if_if_is_false_and_unless_is_true
    branch = StateMachines::Branch.new(if: -> { false }, unless: -> { true })

    refute_match branch, @object
  end

  def test_should_not_match_if_if_is_false_and_unless_is_false
    branch = StateMachines::Branch.new(if: -> { false }, unless: -> { false })

    refute_match branch, @object
  end

  def test_should_not_match_if_if_is_true_and_unless_is_true
    branch = StateMachines::Branch.new(if: -> { true }, unless: -> { true })

    refute_match branch, @object
  end
end
