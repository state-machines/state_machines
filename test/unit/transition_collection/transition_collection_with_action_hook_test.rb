require_relative '../../test_helper'
require_relative 'transition_collection_with_action_hook_base_test.rb'

class TransitionCollectionWithActionHookTest < TransitionCollectionWithActionHookBaseTest
  def setup
    super
    @result = StateMachines::TransitionCollection.new([@transition]).perform
  end

  def test_should_succeed
    assert_equal true, @result
  end

  def test_should_run_action
    assert @object.saved
  end

  def test_should_not_have_already_persisted_when_running_action
    assert_equal 'parked', @object.state_on_save
  end

  def test_should_persist
    assert_equal 'idling', @object.state
  end

  def test_should_not_have_event_during_action
    assert_nil @object.state_event_on_save
  end

  def test_should_not_write_event
    assert_nil @object.state_event
  end

  def test_should_have_event_transition_during_action
    assert_equal @transition, @object.state_event_transition_on_save
  end

  def test_should_not_write_event_transition
    assert_nil @object.send(:state_event_transition)
  end

  def test_should_mark_event_transition_as_transient
    assert @transition.transient?
  end
end
