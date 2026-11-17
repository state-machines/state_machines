# frozen_string_literal: true

require 'test_helper'

class CallbackAssertionsTest < StateMachinesTest
  GUARD = -> { true }

  class Probe
    state_machine :state, initial: :parked do
      event(:ignite) { transition parked: :idling }
      event(:crash) { transition idling: :parked }
      event(:wait) { transition all => same }

      before_transition any => :idling, do: :warm_up
      before_transition all - :parked => :parked, do: :cool_down
      before_transition all => same, do: :idle_again
      before_transition on: all - :crash, do: :log_calm
      after_transition to: :parked, do: ->(_probe) {}
      after_transition on: :ignite, do: :beep, if: GUARD
      after_transition on: :ignite, do: :honk, if: %i[sober? awake?], unless: :raining?
    end
  end

  def setup
    @machine = Probe.state_machine
  end

  def assert_assertion_fails(pattern = /to be defined, but it was not found/, &)
    error = assert_raises(Minitest::Assertion, &)
    assert_match pattern, error.message
  end

  def test_all_source_matches_any_state
    assert_before_transition(@machine, from: :parked, to: :idling, do: :warm_up)
  end

  def test_excluded_source_does_not_match
    assert_before_transition(@machine, from: :idling, to: :parked, do: :cool_down)
    assert_assertion_fails { assert_before_transition(@machine, from: :parked, do: :cool_down) }
  end

  def test_loopback_matches_the_state_it_left
    assert_before_transition(@machine, from: :idling, to: :idling, do: :idle_again)
    assert_before_transition(@machine, to: :parked, do: :idle_again)
  end

  def test_loopback_does_not_match_another_state
    assert_assertion_fails { assert_before_transition(@machine, from: :parked, to: :idling, do: :idle_again) }
  end

  def test_excluded_event_does_not_match
    assert_before_transition(@machine, on: :ignite, do: :log_calm)
    assert_assertion_fails { assert_before_transition(@machine, on: :crash, do: :log_calm) }
  end

  def test_nil_state_is_an_expectation
    assert_assertion_fails(/to: nil/) { assert_before_transition(@machine, to: nil, do: :warm_up) }
  end

  def test_a_lambda_callback_does_not_match_a_method_name
    assert_assertion_fails { assert_after_transition(@machine, to: :parked, do: :tow) }
  end

  def test_method_names_match_as_string_or_symbol
    assert_after_transition(@machine, on: :ignite, do: 'beep')
  end

  def test_a_lambda_condition_does_not_match_a_method_name
    assert_assertion_fails { assert_after_transition(@machine, on: :ignite, do: :beep, if: :sober?) }
  end

  def test_a_lambda_condition_matches_itself
    assert_after_transition(@machine, on: :ignite, do: :beep, if: GUARD)
  end

  def test_array_conditions_match_each_member
    assert_after_transition(@machine, on: :ignite, do: :honk, if: :awake?)
    assert_after_transition(@machine, on: :ignite, do: :honk, if: %i[sober? awake?], unless: :raining?)
  end

  def test_array_conditions_do_not_match_an_absent_member
    assert_assertion_fails { assert_after_transition(@machine, on: :ignite, do: :honk, if: :hungry?) }
  end
end
