# frozen_string_literal: true

require 'test_helper'

# A transition paused inside an around callback (ActiveRecord's valid?) and
# resumed later (its save) must behave as if it never paused: the action sees
# what the around set before yielding, the around sees what the action set,
# and an exception in the action unwinds through the around.
module TransitionResumedContext
  def setup
    @log = log = []
    @klass = Class.new
    @machine = StateMachines::Machine.new(@klass, initial: :parked) do
      event(:ignite) { transition parked: :idling }
      around_transition do |_object, _transition, block|
        Thread.current[:sm_tenant] = :company
        Fiber[:sm_region] = :eu
        begin
          block.call
          log << [:around_out, Thread.current[:sm_status], Fiber[:sm_phase]]
        ensure
          log << :around_ensure
        end
      end
    end
    @transition = @machine.events[:ignite].transition_for(@klass.new)
  end

  def teardown
    %i[sm_tenant sm_status].each { |key| Thread.current[key] = nil }
    %i[sm_region sm_phase].each { |key| Fiber[key] = nil }
  end

  def action
    @log << [:action, Thread.current[:sm_tenant], Fiber[:sm_region]]
    Thread.current[:sm_status] = :done
    Fiber[:sm_phase] = :saved
    { success: true }
  end

  def perform(&)
    pause
    @transition.run_callbacks(after: true, **resume_options, &)
  end

  def test_should_share_context_between_around_and_action
    perform { action }

    assert_equal [%i[action company eu], %i[around_out done saved], :around_ensure], @log
  end

  def test_should_unwind_the_around_when_the_action_raises
    pause
    error = assert_raises(RuntimeError) { @transition.run_callbacks(after: true, **resume_options) { raise 'boom' } }

    assert_equal 'boom', error.message
    refute_predicate @transition, :paused?
    assert_equal [:around_ensure], @log
  end
end

class TransitionResumedWithFibersContextTest < StateMachinesTest
  include TransitionResumedContext

  def pause = @transition.run_callbacks(after: false) { { success: true } }
  def resume_options = {}

  def test_should_unwind_the_around_when_resume_raises
    pause
    assert_raises(RuntimeError) { @transition.resume! { raise 'boom' } }

    refute_predicate @transition, :paused?
    assert_equal [:around_ensure], @log
  end
end

class TransitionResumedWithoutFibersContextTest < StateMachinesTest
  include TransitionResumedContext

  def pause = @transition.run_callbacks(after: false) { { success: true } }
  def resume_options = { fiber: false }
end

# The reference: the same transition when nothing pauses
class TransitionUnpausedContextTest < StateMachinesTest
  include TransitionResumedContext

  def pause; end
  def resume_options = {}
end
