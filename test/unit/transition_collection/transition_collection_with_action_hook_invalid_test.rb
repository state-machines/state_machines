require_relative '../../test_helper'
require_relative 'transition_collection_with_action_hook_base_test.rb'

class TransitionCollectionWithActionHookInvalidTest < TransitionCollectionWithActionHookBaseTest
  def setup
    super
    @result = StateMachines::TransitionCollection.new([@transition, nil]).perform
  end

  def test_should_not_succeed
    assert_equal false, @result
  end

  def test_should_not_run_action
    refute @object.saved
  end
end
