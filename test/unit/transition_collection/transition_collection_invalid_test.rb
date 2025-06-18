# frozen_string_literal: true

require 'test_helper'

class TransitionCollectionInvalidTest < StateMachinesTest
  def setup
    @transitions = StateMachines::TransitionCollection.new([false])
  end

  def test_should_be_empty
    assert_empty @transitions
  end

  def test_should_not_succeed
    assert_equal false, @transitions.perform
  end

  def test_should_not_run_perform_block
    ran_block = false
    @transitions.perform { ran_block = true }

    refute ran_block
  end
end
