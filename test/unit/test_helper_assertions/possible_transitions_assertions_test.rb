# frozen_string_literal: true

require 'test_helper'

class PossibleTransitionsAssertionsTest < StateMachinesTest
  class Rocket
    attr_accessor :fuelled

    state_machine :state, initial: :grounded do
      event :launch do
        transition grounded: :flying, if: :fuelled
        transition grounded: :scrubbed
      end

      event :land do
        transition flying: :grounded
      end

      event :hold do
        transition all - :flying => same
      end

      event :scrub do
        transition all - %i[grounded scrubbed] => :scrubbed
      end

      event :reset do
        transition scrubbed: nil
      end

      event :refuel do
        transition nil => :grounded
      end
    end
  end

  def setup
    @machine = Rocket.state_machine
  end

  def assert_assertion_fails(pattern, &)
    error = assert_raises(Minitest::Assertion, &)
    assert_match pattern, error.message
  end

  def test_collects_every_branch_ignoring_guards_and_order
    assert_sm_possible_transitions(@machine, from: :grounded, expected_to_states: %i[grounded scrubbed flying])
  end

  def test_does_not_count_branches_that_only_lead_to_the_state
    assert_sm_possible_transitions(@machine, from: :flying, expected_to_states: %i[grounded scrubbed])
  end

  def test_includes_transitions_into_the_nil_state
    assert_sm_possible_transitions(@machine, from: :scrubbed, expected_to_states: [:scrubbed, nil])
  end

  def test_works_from_the_nil_state
    assert_sm_possible_transitions(@machine, from: nil, expected_to_states: [nil, :grounded, :scrubbed])
  end

  def test_accepts_string_names
    assert_sm_possible_transitions(@machine, from: 'flying', expected_to_states: %w[scrubbed grounded])
  end

  def test_fails_on_a_missing_target
    assert_assertion_fails(/from :flying to \[:grounded\] but got \[:grounded, :scrubbed\]/) do
      assert_sm_possible_transitions(@machine, from: :flying, expected_to_states: [:grounded])
    end
  end

  def test_fails_on_an_unreachable_target
    assert_assertion_fails(/but got/) do
      assert_sm_possible_transitions(@machine, from: :scrubbed, expected_to_states: %i[scrubbed grounded])
    end
  end

  def test_raises_on_an_unknown_source_state
    assert_raises(IndexError) { assert_sm_possible_transitions(@machine, from: :orbiting, expected_to_states: []) }
  end

  def test_raises_on_an_unknown_target_state
    assert_raises(IndexError) { assert_sm_possible_transitions(@machine, from: :flying, expected_to_states: [:orbiting]) }
  end
end
