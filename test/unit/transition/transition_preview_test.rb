# frozen_string_literal: true

require 'test_helper'

# A preview (run_callbacks with after: false, e.g. ActiveRecord's valid?)
# followed by the full run must behave exactly like the full run alone: the
# around callbacks only ever run inside the full run, on its own stack.
module TransitionPreviewBehavior
  class Fatal < Exception; end # rubocop:disable Lint/InheritException

  def setup
    @log = log = []
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked) do
      event(:ignite) { transition parked: :idling }
      before_transition { log << :before }
      around_transition do |_object, _transition, block|
        previous = Fiber[:sm_tenant]
        Thread.current[:sm_tenant] = :tenant
        Fiber[:sm_tenant] = :tenant
        log << :around_in
        block.call
        log << [:around_out, Thread.current[:sm_tenant], Fiber[:sm_tenant]]
      ensure
        Fiber[:sm_tenant] = previous
        log << :around_ensure
      end
      after_transition { log << :after }
      after_failure { log << :failure }
    end
    @transition = @machine.events[:ignite].transition_for(@klass.new)
  end

  def teardown
    Thread.current[:sm_tenant] = nil
    Fiber[:sm_tenant] = nil
  end

  def run_transition(&)
    preview
    @transition.run_callbacks(&)
  end

  def test_should_run_the_action_once_inside_the_around
    run_transition do
      @log << [:action, Thread.current[:sm_tenant], Fiber[:sm_tenant]]
      { success: true }
    end

    assert_equal [:before, :around_in, %i[action tenant tenant], %i[around_out tenant tenant], :around_ensure, :after], @log
  end

  def test_should_let_the_around_see_context_the_action_deleted
    run_transition do
      Thread.current[:sm_tenant] = nil
      Fiber[:sm_tenant] = nil
      { success: true }
    end

    assert_includes @log, [:around_out, nil, nil]
  end

  def test_should_leave_the_callers_context_as_the_around_restored_it
    Fiber[:sm_tenant] = :original
    run_transition { { success: true } }

    assert_equal :original, Fiber[:sm_tenant]
  end

  def test_should_not_run_afters_when_the_action_fails
    run_transition { { success: false } }

    assert_equal %i[before around_in around_ensure failure], @log
  end

  def test_should_unwind_the_around_when_the_action_raises
    assert_raises(RuntimeError) { run_transition { raise 'boom' } }

    assert_equal %i[before around_in around_ensure], @log
  end

  def test_should_unwind_the_around_for_any_exception
    assert_raises(Fatal) { run_transition { raise Fatal } }

    assert_equal %i[before around_in around_ensure], @log
  end
end

class TransitionPreviewedThenRunTest < StateMachinesTest
  include TransitionPreviewBehavior

  def preview
    @transition.run_callbacks(after: false) { { success: true } }
  end

  def test_should_only_run_befores_before_the_first_around
    preview

    assert_equal [:before], @log
  end

  def test_should_run_failure_callbacks_when_the_preview_fails
    @transition.run_callbacks(after: false) { { success: false } }

    assert_equal %i[before failure], @log
  end

  def test_should_leave_nothing_entered_without_the_full_run
    preview

    refute_includes @log, :around_in
    assert_predicate @transition, :previewed?
  end
end

# The reference: the full run alone
class TransitionRunWithoutPreviewTest < StateMachinesTest
  include TransitionPreviewBehavior

  def preview; end
end

class TransitionPreviewOrderTest < StateMachinesTest
  def setup
    @log = log = []
    @calls = calls = Hash.new(0)
    klass = Class.new
    @machine = StateMachines::Machine.new(klass, initial: :parked) do
      event(:ignite) { transition parked: :idling }
      before_transition(if: ->(_) { calls[:first] += 1 }) { log << :first_before }
      around_transition(if: ->(_) { (calls[:around] += 1) == 2 }) do |_object, _transition, block|
        log << :around_in
        block.call
        log << :around_out
      end
      before_transition { log << :second_before }
    end
    @transition = @machine.events[:ignite].transition_for(klass.new)
  end

  def action
    @log << :action
    { success: true }
  end

  def test_should_interleave_as_declared_without_a_preview
    @calls[:around] = 1
    @transition.run_callbacks { action }

    assert_equal %i[first_before around_in second_before action around_out], @log
  end

  def test_should_run_every_before_in_the_preview
    @transition.run_callbacks(after: false) { action }

    assert_equal %i[first_before second_before action], @log
  end

  def test_should_not_evaluate_around_conditions_in_the_preview
    @transition.run_callbacks(after: false) { action }

    assert_equal 0, @calls[:around]
  end

  def test_should_wrap_only_the_action_after_a_preview
    @calls[:around] = 1
    @transition.run_callbacks(after: false) { { success: true } }
    @log.clear
    @transition.run_callbacks { action }

    assert_equal %i[around_in action around_out], @log
  end

  def test_should_evaluate_each_condition_once
    @transition.run_callbacks { action }

    assert_equal({ first: 1, around: 1 }, @calls)
  end

  def test_should_not_run_befores_without_before_or_after
    @transition.run_callbacks(before: false, after: false) { action }

    assert_empty @log
  end
end

# A before declared after an around must count for validation too: the
# preview runs it, so the preview and the full run agree
class TransitionPreviewValidationAgreementTest < StateMachinesTest
  def setup
    klass = Class.new { attr_accessor :token }
    @machine = StateMachines::Machine.new(klass, initial: :parked) do
      event(:ignite) { transition parked: :idling }
      around_transition { |_object, _transition, block| block.call }
      before_transition { |object| object.token = :issued }
    end
    @object = klass.new
    @transition = @machine.events[:ignite].transition_for(@object)
  end

  def test_should_validate_with_what_every_before_set
    seen = nil
    @transition.run_callbacks(after: false) do
      seen = @object.token
      { success: true }
    end

    assert_equal :issued, seen
  end
end
