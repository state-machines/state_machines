# frozen_string_literal: true

require 'test_helper'
require_relative 'transition_collection_with_action_hook_base'

class TransitionCollectionWithActionHookInvalidTest < StateMachinesTest
  include TransitionCollectionWithActionHookBase

  def setup
    super
    @result = StateMachines::TransitionCollection.new([@transition, nil]).perform
  end

  def test_should_not_succeed
    refute @result
  end

  def test_should_not_run_action
    refute @object.saved
  end
end
