# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class ConcurrentTransitionTest < Minitest::Test
  include StateMachines::TestHelper

  CALLERS = 4
  EJECT_DELAY = 0.03

  class EscapePod
    attr_accessor :launches

    state_machine :pod, initial: :docked, async: true do
      event(:eject) { transition docked: :away }
      event(:recover) { transition away: :docked }

      before_transition(on: :eject) { sleep EJECT_DELAY }
      after_transition(on: :eject) { |pod| pod.launches += 1 }
    end
  end

  class Beacon
    attr_accessor :trail

    state_machine :signal, initial: :idle, async: true do
      event(:transmit) { transition idle: :sent }
      event(:ping) { transition all => same }

      before_transition(on: :transmit) do |beacon|
        beacon.trail << beacon.signal
        beacon.trail << beacon.ping
      end
    end
  end

  def setup
    skip "Async tests not supported on #{RUBY_ENGINE}" if %w[jruby truffleruby].include?(RUBY_ENGINE)

    @pod = EscapePod.new
    @pod.launches = 0
  end

  def test_one_way_transition_is_performed_once_across_threads
    results = CALLERS.times.map { Thread.new { Async { @pod.eject_async.wait }.wait } }.map(&:value)

    assert_equal 1, results.count(true)
    assert_equal CALLERS - 1, results.count(false)
    assert_equal 'away', @pod.pod
    assert_equal 1, @pod.launches
  end

  def test_one_way_transition_is_performed_once_across_fibers_of_one_reactor
    results = Async { CALLERS.times.map { @pod.eject_async }.map(&:wait) }.wait

    assert_equal 1, results.count(true)
    assert_equal CALLERS - 1, results.count(false)
    assert_equal 'away', @pod.pod
    assert_equal 1, @pod.launches
  end

  def test_refused_callers_release_the_machine
    Async { CALLERS.times.map { @pod.eject_async }.map(&:wait) }.wait

    Async do
      assert @pod.recover_async.wait
      assert @pod.eject_async.wait
    end.wait

    assert_equal 'away', @pod.pod
    assert_equal 2, @pod.launches
  end

  def test_a_callback_can_read_the_state_and_fire_another_event
    beacon = Beacon.new
    beacon.trail = []

    assert Async { beacon.transmit_async.wait }.wait
    assert_equal 'sent', beacon.signal
    assert_equal ['idle', true], beacon.trail
  end
end
