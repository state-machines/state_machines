# frozen_string_literal: true

require 'test_helper'

# A transition first run as a preview (after: false, e.g. valid?) must, once
# fully run, behave exactly like one that was never previewed
class TransitionCollectionWithCompletedPreviewTest < StateMachinesTest
  def setup
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked)
    @machine.event(:ignite) { transition parked: :idling }
    @object = @klass.new
    @transition = @machine.events[:ignite].transition_for(@object)
  end

  def perform_twice
    Array.new(2) { StateMachines::TransitionCollection.new([@transition]).perform }
  end

  def test_should_perform_again_without_a_preview
    assert_equal [true, true], perform_twice
  end

  def test_should_perform_again_after_a_preview
    StateMachines::TransitionCollection.new([@transition], after: false).perform

    assert_equal [true, true], perform_twice
    refute_predicate @transition, :previewed?
  end
end

# When a later machine's transition halts, every earlier transition in the
# collection fails with it, and runs its failure callbacks, previewed or not
class TransitionCollectionWithHaltInLaterMachineTest < StateMachinesTest
  def setup
    @log = log = []
    @klass = Class.new
    first = StateMachines::Machine.new(@klass, :state, initial: :parked)
    first.event(:ignite) { transition parked: :idling }
    first.before_transition { log << :first }
    first.after_failure { log << :first_failure }
    second = StateMachines::Machine.new(@klass, :alarm_state, initial: :off)
    second.event(:arm) { transition off: :on }
    second.before_transition do
      log << :second
      throw :halt
    end
    second.after_failure { log << :second_failure }
    object = @klass.new
    @transitions = [first.events[:ignite].transition_for(object), second.events[:arm].transition_for(object)]
  end

  def test_should_fail_every_transition_in_a_full_run
    refute StateMachines::TransitionCollection.new(@transitions).perform
    assert_equal %i[first second second_failure first_failure], @log
  end

  def test_should_fail_every_transition_in_a_preview
    refute StateMachines::TransitionCollection.new(@transitions, after: false).perform
    assert_equal %i[first second second_failure first_failure], @log
  end
end
