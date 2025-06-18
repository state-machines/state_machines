# frozen_string_literal: true

require 'test_helper'
require_relative 'transition_collection_with_action_hook_base_test'

class TransitionCollectionWithActionHookAndSkippedActionTest < TransitionCollectionWithActionHookBaseTest
  def setup
    super
    @result = StateMachines::TransitionCollection.new([@transition], actions: false).perform
  end

  def test_should_succeed
    assert_equal true, @result
  end

  def test_should_not_run_action
    refute @object.saved
  end
end
