# frozen_string_literal: true

require 'test_helper'

# Preview bookkeeping exists only from a successful preview to the end of its
# full run: every other outcome leaves the transition like one never
# previewed.
class TransitionPreviewBookkeepingTest < StateMachinesTest
  OUTCOMES = %i[succeeded failed halted raised].freeze

  def setup
    @log = log = []
    @klass = Class.new { attr_accessor :halt, :raise_around }
    @machine = StateMachines::Machine.new(@klass, initial: :parked) do
      event(:ignite) { transition parked: :idling }
      before_transition do |object|
        log << :before
        throw :halt if object.halt
      end
      around_transition do |object, _transition, block|
        log << :around
        if object.raise_around
          object.raise_around = false
          raise 'around'
        end
        block.call
      end
      after_transition { log << :after }
      after_failure { log << :failure }
    end
  end

  def new_transition
    object = @klass.new
    [object, @machine.events[:ignite].transition_for(object)]
  end

  # Runs a preview (after: false) or a full run ending in +outcome+
  def attempt(object, transition, outcome, preview:)
    object.halt = outcome == :halted
    transition.run_callbacks(after: !preview) do
      @log << (preview ? :validate : :action)
      raise 'action' if outcome == :raised

      { success: outcome != :failed }
    end
  rescue RuntimeError
    @log << :raised
  ensure
    object.halt = false
  end

  def reuse(transition)
    StateMachines::TransitionCollection.new([transition]).perform do
      @log << :action
      true
    end
  end

  # The log of a full run ending in +outcome+, then a reuse
  def full_run_then_reuse(object, transition, outcome)
    @log.clear
    attempt(object, transition, outcome, preview: false)
    full = @log.dup
    @log.clear
    reuse(transition)
    [full, @log.dup]
  end

  def never_previewed(outcome)
    full_run_then_reuse(*new_transition, outcome)
  end

  # Halted, failed or raised previews leave nothing: the full run and the
  # reuse are those of a transition never previewed
  def test_unsuccessful_previews_leave_no_trace
    (OUTCOMES - [:succeeded]).product(OUTCOMES).each do |preview_outcome, run_outcome|
      object, transition = new_transition
      attempt(object, transition, preview_outcome, preview: true)

      refute_predicate transition, :previewed?, preview_outcome
      assert_equal never_previewed(run_outcome), full_run_then_reuse(object, transition, run_outcome),
                   "#{preview_outcome} preview, #{run_outcome} run"
    end
  end

  # A successful preview's full run skips the befores it ran; however that run
  # ends, the reuse is that of a transition never previewed
  def test_full_runs_end_successful_previews
    OUTCOMES.each do |run_outcome|
      object, transition = new_transition
      attempt(object, transition, :succeeded, preview: true)
      _full, reused = full_run_then_reuse(object, transition, run_outcome)

      refute_predicate transition, :previewed?, run_outcome
      assert_equal never_previewed(run_outcome).last, reused, "#{run_outcome} run"
    end
  end

  def halting_preview
    object, transition = new_transition
    object.halt = true
    [transition, transition.run_callbacks(after: false) { { success: true } }]
  end

  def test_should_fail_a_preview_whose_before_halts
    _transition, result = halting_preview

    refute result
    assert_equal %i[before failure], @log
  end

  # chaos: a halting before must halt the full run too, with its afters
  def test_should_rerun_a_before_that_halted_the_preview
    transition, = halting_preview

    refute(transition.run_callbacks { { success: true } })
    assert_equal %i[before failure before failure], @log
  end

  # chaos: a full run that raises must not let the retry skip the befores
  def test_should_rerun_befores_after_a_full_run_raised
    object, transition = new_transition
    transition.run_callbacks(after: false) { { success: true } }
    object.raise_around = true
    assert_raises(RuntimeError) { transition.run_callbacks { { success: true } } }
    @log.clear
    reuse(transition)

    assert_equal %i[before around action after], @log
  end
end
