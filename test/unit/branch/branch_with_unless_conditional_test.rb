# frozen_string_literal: true

require 'test_helper'

class BranchWithUnlessConditionalTest < StateMachinesTest
  def setup
    @object = Object.new
  end

  def test_should_have_an_unless_condition
    branch = StateMachines::Branch.new(unless: -> { true })

    refute_nil branch.unless_condition
  end

  def test_should_match_if_false
    branch = StateMachines::Branch.new(unless: -> { false })

    assert branch.matches?(@object)
  end

  def test_should_not_match_if_true
    branch = StateMachines::Branch.new(unless: -> { true })

    refute branch.matches?(@object)
  end

  def test_should_be_nil_if_unmatched
    branch = StateMachines::Branch.new(unless: -> { true })

    assert_nil branch.match(@object)
  end
end
