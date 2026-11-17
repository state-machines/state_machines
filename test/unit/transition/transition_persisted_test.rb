# frozen_string_literal: true

require 'test_helper'

# Transition#persisted?: whether the transition's state change is in place,
# however the transition is run (directly, through perform, previewed).
class TransitionPersistedTest < StateMachinesTest
  def setup
    @klass = Class.new do
      attr_accessor :save_result, :save_error

      def save
        raise save_error if save_error

        save_result
      end
    end

    @machine = StateMachines::Machine.new(@klass, action: :save, initial: :parked)
    @machine.event(:ignite) { transition parked: :idling }

    @object = @klass.new
    @object.save_result = true
  end

  def transition
    @transition ||= @machine.events[:ignite].transition_for(@object)
  end

  def test_should_not_be_persisted_when_new
    refute_predicate transition, :persisted?
  end

  def test_should_be_persisted_after_persist
    transition.persist

    assert_predicate transition, :persisted?
  end

  def test_should_not_be_persisted_after_rollback
    transition.persist
    transition.rollback

    refute_predicate transition, :persisted?
  end

  def test_should_not_be_persisted_after_reset
    transition.persist
    transition.reset

    refute_predicate transition, :persisted?
  end

  def test_should_be_persisted_after_a_successful_perform
    assert transition.perform

    assert_predicate transition, :persisted?
  end

  def test_should_be_persisted_after_a_perform_without_the_action
    assert transition.perform(false)

    assert_predicate transition, :persisted?
  end

  def test_should_not_be_persisted_when_a_before_callback_halts
    @machine.before_transition { throw :halt }

    refute transition.perform
    refute_predicate transition, :persisted?
  end

  def test_should_not_be_persisted_when_the_action_fails
    @object.save_result = false

    refute transition.perform
    refute_predicate transition, :persisted?
    assert_equal 'parked', @object.state
  end

  def test_should_not_be_persisted_when_the_action_raises
    @object.save_error = ArgumentError

    assert_raises(ArgumentError) { transition.perform }
    refute_predicate transition, :persisted?
  end

  def test_should_stay_persisted_when_an_after_callback_halts
    @machine.after_transition { throw :halt }

    assert transition.perform
    assert_predicate transition, :persisted?
  end

  def test_should_stay_persisted_when_an_around_callback_halts_after_yielding
    @machine.around_transition do |_object, _transition, block|
      block.call
      throw :halt
    end

    assert transition.perform
    assert_predicate transition, :persisted?
  end

  def test_should_stay_persisted_when_an_around_callback_raises_after_yielding
    @machine.around_transition do |_object, _transition, block|
      block.call
      raise ArgumentError
    end

    assert_raises(ArgumentError) { transition.perform(false) }
    assert_predicate transition, :persisted?
    assert_equal 'idling', @object.state
  end

  def test_should_be_persisted_after_a_successful_preview
    assert StateMachines::TransitionCollection.new([transition], after: false).perform

    assert_predicate transition, :previewed?
    assert_predicate transition, :persisted?
  end

  def test_should_not_be_persisted_after_a_failed_preview
    @object.save_result = false

    refute StateMachines::TransitionCollection.new([transition], after: false).perform
    refute_predicate transition, :persisted?
  end
end
