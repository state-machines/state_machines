require_relative '../../test_helper'

class TransitionCollectionEmptyWithBlockTest < StateMachinesTest
  def setup
    @transitions = StateMachines::TransitionCollection.new
  end

  def test_should_raise_exception_if_perform_raises_exception
    assert_raises(ArgumentError) { @transitions.perform { fail ArgumentError } }
  end

  def test_should_use_block_result_if_non_boolean
    assert_equal 1, @transitions.perform { 1 }
  end

  def test_should_use_block_result_if_false
    assert_equal false, @transitions.perform { false }
  end

  def test_should_use_block_reslut_if_nil
    assert_equal nil, @transitions.perform { nil }
  end
end
