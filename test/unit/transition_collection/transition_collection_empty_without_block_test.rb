require_relative '../../test_helper'

class TransitionCollectionEmptyWithoutBlockTest < StateMachinesTest
  def setup
    @transitions = StateMachines::TransitionCollection.new
    @result = @transitions.perform
  end

  def test_should_succeed
    assert_equal true, @result
  end
end
