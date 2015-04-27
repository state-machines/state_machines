require_relative '../../test_helper'

class TransitionCollectionByDefaultTest < StateMachinesTest
  def setup
    @transitions = StateMachines::TransitionCollection.new
  end

  def test_should_not_skip_actions
    refute @transitions.skip_actions
  end

  def test_should_not_skip_after
    refute @transitions.skip_after
  end

  def test_should_use_transaction
    assert @transitions.use_transactions
  end

  def test_should_be_empty
    assert @transitions.empty?
  end
end
