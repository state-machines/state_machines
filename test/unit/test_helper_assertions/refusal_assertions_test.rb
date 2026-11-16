# frozen_string_literal: true

require 'test_helper'

class RefusalAssertionsTest < StateMachinesTest
  class Shuttle
    attr_accessor :fuelled, :abort_launch, :save_result

    def initialize
      @fuelled = true
      @save_result = true
      super
    end

    def save
      save_result
    end

    state_machine :state, initial: :grounded, action: :save do
      before_transition on: :launch do |shuttle|
        throw :halt if shuttle.abort_launch
      end

      event :launch do
        transition grounded: :flying, if: :fuelled
      end

      event :land do
        transition flying: :grounded
      end
    end

    state_machine :beacon_state, initial: :dark, namespace: 'beacon' do
      event :enable do
        transition dark: :lit
      end

      event :disable do
        transition lit: :dark
      end
    end
  end

  def setup
    @shuttle = Shuttle.new
  end

  def assert_assertion_fails(pattern, &block)
    error = assert_raises(Minitest::Assertion, &block)
    assert_match pattern, error.message
    error
  end

  # === assert_sm_refused ===

  def test_refused_passes_for_any_reason_and_returns_it
    assert_equal :no_transition, assert_sm_refused(@shuttle, :land)
  end

  def test_refused_checks_no_transition
    assert_sm_refused(@shuttle, :land, :no_transition)
  end

  def test_refused_checks_guard
    @shuttle.fuelled = false

    assert_sm_refused(@shuttle, :launch, :guard)
  end

  def test_refused_checks_halted
    @shuttle.abort_launch = true

    assert_sm_refused(@shuttle, :launch, :halted)
  end

  def test_refused_checks_action_failed_and_leaves_the_state_alone
    @shuttle.save_result = false

    assert_sm_refused(@shuttle, :launch, :action_failed)
    assert_sm_state(@shuttle, :grounded)
  end

  def test_refused_fails_when_the_event_succeeds
    assert_assertion_fails(/Expected :launch on state to be refused, but it transitioned :grounded -> :flying/) do
      assert_sm_refused(@shuttle, :launch)
    end
  end

  def test_refused_fails_for_another_reason
    @shuttle.fuelled = false

    assert_assertion_fails(/to be refused for :halted, but was refused for :guard/) do
      assert_sm_refused(@shuttle, :launch, :halted)
    end
  end

  def test_refused_uses_the_custom_message
    assert_assertion_fails(/shuttle should stay grounded/) do
      assert_sm_refused(@shuttle, :launch, message: 'shuttle should stay grounded')
    end
  end

  def test_refused_rejects_an_unknown_reason
    error = assert_raises(ArgumentError) { assert_sm_refused(@shuttle, :launch, :gaurd) }

    assert_equal 'Unknown refusal reason :gaurd. Did you mean :guard? Valid reasons: [:no_transition, :guard, :halted, :action_failed, :contended]', error.message
  end

  def test_refused_validates_the_reason_before_firing
    assert_raises(ArgumentError) { assert_sm_refused(@shuttle, :launch, :gaurd) }

    assert_sm_state(@shuttle, :grounded)
  end

  def test_refused_rejects_an_unknown_event
    error = assert_raises(ArgumentError) { assert_sm_refused(@shuttle, :warp) }

    assert_match(/No event :warp found on machine :state/, error.message)
  end

  def test_refused_rejects_an_unknown_machine
    error = assert_raises(ArgumentError) { assert_sm_refused(@shuttle, :land, machine_name: :hull) }

    assert_match(/No state machine 'hull' found/, error.message)
  end

  def test_refused_supports_namespaced_machines_by_plain_or_qualified_name
    @shuttle.enable_beacon

    assert_sm_refused(@shuttle, :enable, :no_transition, machine_name: :beacon_state)
    assert_sm_refused(@shuttle, :enable_beacon, :no_transition, machine_name: :beacon_state)
  end

  def test_refused_fails_when_a_namespaced_event_succeeds
    assert_assertion_fails(/Expected :enable_beacon on beacon_state to be refused/) do
      assert_sm_refused(@shuttle, :enable, machine_name: :beacon_state)
    end
  end

  # === assert_sm_refusal / refute_sm_refusal ===

  def test_refusal_reads_the_recorded_reason_without_firing
    @shuttle.land

    assert_equal :no_transition, assert_sm_refusal(@shuttle, :land, :no_transition)
    assert_sm_state(@shuttle, :grounded)
  end

  def test_refusal_fails_when_nothing_was_recorded
    assert_assertion_fails(/to be refused for :guard, but no refusal was recorded/) do
      assert_sm_refusal(@shuttle, :launch, :guard)
    end
  end

  def test_refusal_fails_for_another_reason
    @shuttle.land

    assert_assertion_fails(/to be refused for :guard, but it was refused for :no_transition/) do
      assert_sm_refusal(@shuttle, :land, :guard)
    end
  end

  def test_refusal_rejects_an_unknown_reason
    assert_raises(ArgumentError) { assert_sm_refusal(@shuttle, :land, :nope) }
  end

  def test_refute_refusal_passes_after_a_success_or_no_attempt
    refute_sm_refusal(@shuttle, :launch)
    @shuttle.launch

    refute_sm_refusal(@shuttle, :launch)
  end

  def test_refute_refusal_fails_after_a_refusal
    @shuttle.land

    assert_assertion_fails(/Expected no refusal for the last :land on state, but it was refused for :no_transition/) do
      refute_sm_refusal(@shuttle, :land)
    end
  end

  def test_refusal_helpers_support_namespaced_machines
    @shuttle.disable_beacon

    assert_sm_refusal(@shuttle, :disable, :no_transition, machine_name: :beacon_state)
    assert_sm_refusal(@shuttle, :disable_beacon, :no_transition, machine_name: :beacon_state)
    refute_sm_refusal(@shuttle, :enable, machine_name: :beacon_state)
  end

  def test_refute_refusal_fails_on_a_namespaced_machine
    @shuttle.disable_beacon

    assert_assertion_fails(/:disable_beacon on beacon_state/) do
      refute_sm_refusal(@shuttle, :disable, machine_name: :beacon_state)
    end
  end

  # === assert_sm_raises_refusal ===

  def test_raises_refusal_returns_the_error
    @shuttle.fuelled = false
    error = assert_sm_raises_refusal(@shuttle, :launch, :guard)

    assert_kind_of StateMachines::InvalidTransition, error
    assert_equal :guard, error.reason
  end

  def test_raises_refusal_fails_when_nothing_is_raised
    assert_assertion_fails(/Expected launch! on state to raise StateMachines::InvalidTransition, but nothing was raised/) do
      assert_sm_raises_refusal(@shuttle, :launch, :guard)
    end
  end

  def test_raises_refusal_fails_for_another_reason
    assert_assertion_fails(/Expected land! on state to be refused for :halted, but was refused for :no_transition/) do
      assert_sm_raises_refusal(@shuttle, :land, :halted)
    end
  end

  def test_raises_refusal_rejects_an_unknown_reason
    assert_raises(ArgumentError) { assert_sm_raises_refusal(@shuttle, :land, :no_transitions) }
  end

  def test_raises_refusal_supports_namespaced_machines
    assert_sm_raises_refusal(@shuttle, :disable, :no_transition, machine_name: :beacon_state)

    assert_assertion_fails(/Expected enable_beacon! on beacon_state to raise/) do
      assert_sm_raises_refusal(@shuttle, :enable_beacon, :no_transition, machine_name: :beacon_state)
    end
  end

  # === assert_sm_parallel_refused ===

  def test_parallel_refused_checks_the_reasons_of_the_culprits_only
    error = assert_sm_parallel_refused(@shuttle, %i[launch disable_beacon], { disable_beacon: :no_transition })

    assert_kind_of StateMachines::InvalidParallelTransition, error
    assert_equal({ launch: :grounded, beacon_state: :dark }, { launch: @shuttle.state_name, beacon_state: @shuttle.beacon_state_name })
  end

  def test_parallel_refused_fails_when_the_events_succeed
    assert_assertion_fails(/Expected fire_events\(:launch, :enable_beacon\) to be refused, but it returned true/) do
      assert_sm_parallel_refused(@shuttle, %i[launch enable_beacon], { launch: :guard })
    end
  end

  def test_parallel_refused_fails_for_other_reasons
    @shuttle.fuelled = false

    assert_assertion_fails(/to be refused for \{launch: :halted\}, but was refused for \{launch: :guard\}/) do
      assert_sm_parallel_refused(@shuttle, %i[launch enable_beacon], { launch: :halted })
    end
  end

  def test_parallel_refused_rejects_unknown_reasons
    error = assert_raises(ArgumentError) { assert_sm_parallel_refused(@shuttle, %i[launch disable_beacon], { disable_beacon: :typo }) }

    assert_match(/Unknown refusal reason :typo/, error.message)
  end

  def test_parallel_refused_rejects_non_hash_expectations
    error = assert_raises(ArgumentError) { assert_sm_parallel_refused(@shuttle, %i[launch disable_beacon], :no_transition) }

    assert_match(/must be a Hash/, error.message)
  end

  # === RSpec-style aliases ===

  def test_rspec_style_aliases
    expect_to_be_refused(@shuttle, :land, :no_transition)
    expect_refusal(@shuttle, :land, :no_transition)
    expect_no_refusal(@shuttle, :launch)
    expect_to_raise_refusal(@shuttle, :land, :no_transition)
    expect_parallel_refused(@shuttle, %i[launch disable_beacon], { disable_beacon: :no_transition })

    assert_sm_no_refusal(@shuttle, :launch)
  end

  # === Existing helpers with a Transition-returning event ===

  def test_sync_execution_accepts_the_returned_transition
    assert_kind_of StateMachines::Transition, Shuttle.new.launch
    assert_sm_sync_execution(@shuttle, :launch, :flying)
  end

  def test_transition_helpers_accept_the_returned_transition
    assert_sm_transition(@shuttle, :launch, :flying)
    assert_sm_event_triggers(@shuttle, :land)
    assert_sm_immediate_execution(@shuttle, :launch)
  end

  # Bug: immediate execution was decided by wall-clock time (< 10ms), so a
  # slow runner failed it. It is decided by what the event did.
  class SlowShuttle
    state_machine :state, initial: :grounded do
      before_transition(on: :launch) { sleep 0.02 }
      event(:launch) { transition grounded: :flying }
    end
  end

  def test_immediate_execution_ignores_how_long_the_event_took
    assert_sm_immediate_execution(SlowShuttle.new, :launch)
  end

  def test_immediate_execution_fails_for_an_event_returning_something_to_wait_on
    pending = Class.new
    @shuttle.define_singleton_method(:launch!) do
      self.state = 'flying'
      pending.new
    end
    assert_assertion_fails(/to return the performed transition, but it returned #<Class/) { assert_sm_immediate_execution(@shuttle, :launch) }
  end

  def test_immediate_execution_fails_when_the_state_has_not_changed_on_return
    @shuttle.define_singleton_method(:launch!) { launch_transition }
    assert_assertion_fails(/should change state before returning/) { assert_sm_immediate_execution(@shuttle, :launch) }
  end
end
