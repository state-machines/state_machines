# frozen_string_literal: true

require 'test_helper'

# A transition paused by a run without after callbacks (ActiveRecord's
# valid?) is completed by a later run with them (its save).  The action must
# run once, on the caller, and the around and after callbacks must see its
# real outcome, with or without fibers for the resume.
class TransitionResumedAfterPauseTest < StateMachinesTest
  def setup
    @log = log = []
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked) do
      event(:ignite) { transition parked: :idling, after: -> { log << :branch_after } }
      around_transition do |_object, _transition, block|
        log << :around_in
        block.call
        log << :around_out
      end
      after_transition { log << :after }
      after_failure { log << :failure }
    end
    @object = @klass.new
    @transition = @machine.events[:ignite].transition_for(@object)
    @transition.run_callbacks(after: false) { { success: true } }
  end

  def resume(success, **)
    @transition.run_callbacks(after: true, **) do
      @log << :action
      { success: success }
    end
  end

  def test_should_be_paused_inside_the_around
    assert_predicate @transition, :paused?
    assert_equal [:around_in], @log
  end

  def test_should_finish_a_successful_resume_without_fibers
    resume(true, fiber: false)

    assert_equal %i[around_in action around_out branch_after after], @log
  end

  def test_should_not_run_afters_on_a_failed_resume_without_fibers
    resume(false, fiber: false)

    assert_equal %i[around_in action failure], @log
  end

  def test_should_finish_a_successful_resume_with_fibers
    resume(true)

    assert_equal %i[around_in action around_out branch_after after], @log
  end

  def test_should_not_run_afters_on_a_failed_resume_with_fibers
    resume(false)

    assert_equal %i[around_in action failure], @log
  end

  def test_should_run_the_action_on_the_callers_fiber
    caller_fiber = Fiber.current
    action_fiber = nil
    @transition.run_callbacks(after: true, fiber: false) do
      action_fiber = Fiber.current
      { success: true }
    end

    assert_same caller_fiber, action_fiber
  end

  def test_should_resume_with_a_continuation
    assert(@transition.resume! do
      @log << :action
      { success: true }
    end)
    assert_equal %i[around_in action around_out], @log
  end
end
