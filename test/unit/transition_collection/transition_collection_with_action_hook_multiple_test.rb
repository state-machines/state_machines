require_relative '../../test_helper'
require_relative 'transition_collection_with_action_hook_base_test.rb'

class TransitionCollectionWithActionHookMultipleTest < TransitionCollectionWithActionHookBaseTest
  def setup
    super

    @status_machine = StateMachines::Machine.new(@klass, :status, initial: :first_gear, action: :save)
    @status_machine.state :second_gear
    @status_machine.event :shift_up

    @klass.class_eval do
      attr_reader :status_on_save, :status_event_on_save, :status_event_transition_on_save

      remove_method :save

      def save
        @saved = true
        @state_on_save = state
        @state_event_on_save = state_event
        @state_event_transition_on_save = state_event_transition
        @status_on_save = status
        @status_event_on_save = status_event
        @status_event_transition_on_save = status_event_transition
        super
        1
      end
    end

    @object = @klass.new
    @state_transition = StateMachines::Transition.new(@object, @machine, :ignite, :parked, :idling)
    @status_transition = StateMachines::Transition.new(@object, @status_machine, :shift_up, :first_gear, :second_gear)

    @result = StateMachines::TransitionCollection.new([@state_transition, @status_transition]).perform
  end

  def test_should_succeed
    assert_equal 1, @result
  end

  def test_should_run_action
    assert @object.saved
  end

  def test_should_not_have_already_persisted_when_running_action
    assert_equal 'parked', @object.state_on_save
    assert_equal 'first_gear', @object.status_on_save
  end

  def test_should_persist
    assert_equal 'idling', @object.state
    assert_equal 'second_gear', @object.status
  end

  def test_should_not_have_events_during_action
    assert_nil @object.state_event_on_save
    assert_nil @object.status_event_on_save
  end

  def test_should_not_write_events
    assert_nil @object.state_event
    assert_nil @object.status_event
  end

  def test_should_have_event_transitions_during_action
    assert_equal @state_transition, @object.state_event_transition_on_save
    assert_equal @status_transition, @object.status_event_transition_on_save
  end

  def test_should_not_write_event_transitions
    assert_nil @object.send(:state_event_transition)
    assert_nil @object.send(:status_event_transition)
  end

  def test_should_mark_event_transitions_as_transient
    assert @state_transition.transient?
    assert @status_transition.transient?
  end
end
