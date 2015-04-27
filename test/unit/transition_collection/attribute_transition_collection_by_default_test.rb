require_relative '../../test_helper'

class AttributeTransitionCollectionByDefaultTest < StateMachinesTest
  def setup
    @transitions = StateMachines::AttributeTransitionCollection.new
  end

  def test_should_skip_actions
    assert @transitions.skip_actions
  end

  def test_should_not_skip_after
    refute @transitions.skip_after
  end

  def test_should_not_use_transaction
    refute @transitions.use_transactions
  end

  def test_should_be_empty
    assert @transitions.empty?
  end
end
