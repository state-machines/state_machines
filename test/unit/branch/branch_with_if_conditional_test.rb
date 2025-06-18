# frozen_string_literal: true

require 'test_helper'

class BranchWithIfConditionalTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_have_an_if_condition
    branch = StateMachines::Branch.new(if: -> { true })

    refute_nil branch.if_condition
  end

  def test_should_match_if_true
    branch = StateMachines::Branch.new(if: -> { true })

    assert branch.matches?(@object)
  end

  def test_should_not_match_if_false
    branch = StateMachines::Branch.new(if: -> { false })

    refute branch.matches?(@object)
  end

  def test_should_be_nil_if_unmatched
    branch = StateMachines::Branch.new(if: -> { false })

    assert_nil branch.match(@object)
  end
end
