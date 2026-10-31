# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class AsyncTransitionCollectionTest < Minitest::Test
  include StateMachines::TestHelper

  class Satellite
    state_machine :orbit, initial: :parked, namespace: :orbit, async: true do
      event(:launch) { transition parked: :cruising }
    end

    state_machine :antenna, initial: :stowed, namespace: :antenna, async: true do
      event(:deploy) { transition stowed: :extended }
    end
  end

  def setup
    skip "Async tests not supported on #{RUBY_ENGINE}" if %w[jruby truffleruby].include?(RUBY_ENGINE)

    @satellite = Satellite.new
    @collection = Satellite.state_machines[:orbit].create_async_transition_collection(
      [
        Satellite.state_machines[:orbit].events[:launch].transition_for(@satellite),
        Satellite.state_machines[:antenna].events[:deploy].transition_for(@satellite)
      ]
    )
  end

  def test_perform_async_runs_the_action_once_and_reports_its_result
    runs = 0

    assert @collection.perform_async { runs += 1 }
    assert_equal 1, runs
    assert_equal 'cruising', @satellite.orbit
    assert_equal 'extended', @satellite.antenna
  end

  def test_perform_async_reports_a_failed_action_and_changes_nothing
    runs = 0

    refute @collection.perform_async { runs += 1 and false }
    assert_equal 1, runs
    assert_equal 'parked', @satellite.orbit
    assert_equal 'stowed', @satellite.antenna
  end

  def test_perform_threaded_runs_the_action_once_and_reports_its_result
    runs = 0

    assert @collection.perform_threaded { runs += 1 }
    assert_equal 1, runs
    assert_equal 'cruising', @satellite.orbit
  end

  def test_perform_threaded_reports_a_failed_action_and_changes_nothing
    runs = 0

    refute @collection.perform_threaded { runs += 1 and false }
    assert_equal 1, runs
    assert_equal 'parked', @satellite.orbit
  end
end
