require_relative '../../test_helper'
require_relative 'transition_collection_with_action_hook_base_test.rb'

class TransitionCollectionWithActionHookWithNilActionTest < TransitionCollectionWithActionHookBaseTest
  def setup
    super

    @machine = StateMachines::Machine.new(@klass, :status, initial: :first_gear)
    @machine.state :second_gear
    @machine.event :shift_up

    @result = StateMachines::TransitionCollection.new([@transition, StateMachines::Transition.new(@object, @machine, :shift_up, :first_gear, :second_gear)]).perform
  end

  def test_should_succeed
    assert_equal true, @result
  end

  def test_should_run_action
    assert @object.saved
  end

  def test_should_have_already_persisted_when_running_action
    assert_equal 'idling', @object.state_on_save
  end

  def test_should_not_have_event_during_action
    assert_nil @object.state_event_on_save
  end

  def test_should_not_write_event
    assert_nil @object.state_event
  end

  def test_should_not_have_event_transition_during_save
    assert_nil @object.state_event_transition_on_save
  end

  def test_should_not_write_event_attribute
    assert_nil @object.send(:state_event_transition)
  end
end
