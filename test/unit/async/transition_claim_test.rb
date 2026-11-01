# frozen_string_literal: true

require File.expand_path('../../test_helper', __dir__)

class TransitionClaimTest < Minitest::Test
  include StateMachines::TestHelper

  CALLERS = 4
  RELEASE_DELAY = 0.03
  HANDOFF_TIMEOUT = 1

  class CargoBay
    attr_accessor :drops

    state_machine :bay, initial: :loaded, async: true do
      event(:release) { transition loaded: :empty }

      before_transition(on: :release) { sleep RELEASE_DELAY }
      after_transition(on: :release) { |bay| bay.drops += 1 }
    end
  end

  class Satellite
    attr_accessor :launches, :deploys

    state_machine :orbit, initial: :parked, async: true do
      event(:launch) { transition parked: :cruising }

      before_transition(on: :launch) { sleep RELEASE_DELAY }
      after_transition(on: :launch) { |satellite| satellite.launches += 1 }
    end

    state_machine :antenna, initial: :stowed, async: true do
      event(:deploy) { transition stowed: :extended }

      after_transition(on: :deploy) { |satellite| satellite.deploys += 1 }
    end
  end

  class Rover
    attr_accessor :arm_callbacks, :driving, :resume_drive

    state_machine :arm, initial: :folded, async: true do
      event(:unfold) { transition folded: :open }

      before_transition(on: :unfold) { |rover| rover.arm_callbacks += 1 }
    end

    state_machine :drive, initial: :idle, async: true do
      event(:roll) { transition idle: :rolling }

      before_transition(on: :roll) do |rover|
        rover.driving.push(:claimed)
        rover.resume_drive.pop(timeout: HANDOFF_TIMEOUT)
      end
    end
  end

  class Outpost
    attr_accessor :supplies, :gate, :deliveries

    state_machine :hatch, initial: :sealed, async: true do
      event(:unseal) { transition sealed: :open }
      event(:supply) { transition open: :stocked }

      before_transition(on: :unseal) do |outpost|
        outpost.deliveries = CALLERS.times.map do
          Async do
            outpost.gate.wait
            outpost.supply_async.wait
          end
        end
      end
      before_transition(on: :supply) { sleep RELEASE_DELAY }
      after_transition(on: :supply) { |outpost| outpost.supplies += 1 }
    end
  end

  class Lander
    attr_accessor :trail

    state_machine :legs, initial: :stowed, async: true do
      event(:extend_legs) { transition stowed: :down }
      event(:ping) { transition all => same }

      before_transition(on: :extend_legs) do |lander|
        lander.trail << lander.legs
        lander.trail << lander.ping
      end
    end
  end

  def setup
    skip "Async tests not supported on #{RUBY_ENGINE}" if %w[jruby truffleruby].include?(RUBY_ENGINE)

    @bay = CargoBay.new
    @bay.drops = 0
  end

  def test_one_way_transition_is_performed_once_across_threads
    collections = CALLERS.times.map { release_collection }
    results = collections.map { |collection| Thread.new { collection.perform_threaded } }.map(&:value)

    assert_equal 1, results.count(true)
    assert_equal CALLERS - 1, results.count(false)
    assert_equal 'empty', @bay.bay
    assert_equal 1, @bay.drops
  end

  def test_one_way_transition_is_performed_once_across_fibers_of_one_reactor
    collections = CALLERS.times.map { release_collection }
    results = Async { collections.map { |collection| Async { collection.perform_async } }.map(&:wait) }.wait

    assert_equal 1, results.count(true)
    assert_equal CALLERS - 1, results.count(false)
    assert_equal 'empty', @bay.bay
    assert_equal 1, @bay.drops
  end

  def test_a_pair_of_machines_is_performed_once_whichever_order_a_collection_lists_them
    satellite = Satellite.new
    satellite.launches = 0
    satellite.deploys = 0

    collections = CALLERS.times.map { |caller| satellite_collection(satellite, reversed: caller.odd?) }
    results = collections.map { |collection| Thread.new { collection.perform_threaded } }.map(&:value)

    assert_equal 1, results.count(true)
    assert_equal CALLERS - 1, results.count(false)
    assert_equal 1, satellite.launches
    assert_equal 1, satellite.deploys
  end

  def test_a_collection_refused_one_claim_performs_none_of_its_transitions
    rover = Rover.new
    rover.arm_callbacks = 0
    rover.driving = Queue.new
    rover.resume_drive = Queue.new

    rolling = Thread.new { rover_collection(rover, only: :drive).perform_threaded }
    rover.driving.pop

    refute rover_collection(rover).perform_threaded
    assert_equal 'folded', rover.arm
    assert_equal 0, rover.arm_callbacks

    rover.resume_drive.push(:go)

    assert rolling.value
    assert rover_collection(rover, only: :arm).perform_threaded
    assert_equal 'open', rover.arm
  end

  def test_fire_events_performs_a_one_way_transition_once
    results = CALLERS.times.map { Thread.new { @bay.fire_events(:release) } }.map(&:value)

    assert_equal 1, results.count(true)
    assert_equal CALLERS - 1, results.count(false)
    assert_equal 'empty', @bay.bay
    assert_equal 1, @bay.drops
  end

  def test_authority_does_not_outlive_the_perform_that_granted_it
    outpost = Outpost.new
    outpost.supplies = 0

    results = Async do
      outpost.gate = Async::Notification.new
      outpost.unseal_async.wait
      outpost.gate.signal
      outpost.deliveries.map(&:wait)
    end.wait

    assert_equal 1, results.count(true)
    assert_equal CALLERS - 1, results.count(false)
    assert_equal 'stocked', outpost.hatch
    assert_equal 1, outpost.supplies
  end

  def test_a_callback_can_read_the_state_and_fire_another_event
    lander = Lander.new
    lander.trail = []
    machine = Lander.state_machines[:legs]

    assert machine.create_async_transition_collection([machine.events[:extend_legs].transition_for(lander)]).perform_threaded
    assert_equal ['stowed', true], lander.trail
  end

  private

  def release_collection
    machine = CargoBay.state_machines[:bay]

    machine.create_async_transition_collection([machine.events[:release].transition_for(@bay)])
  end

  def satellite_collection(satellite, reversed: false)
    orbit = Satellite.state_machines[:orbit]
    antenna = Satellite.state_machines[:antenna]
    transitions = [
      orbit.events[:launch].transition_for(satellite),
      antenna.events[:deploy].transition_for(satellite)
    ]
    transitions.reverse! if reversed

    orbit.create_async_transition_collection(transitions)
  end

  def rover_collection(rover, only: nil)
    arm = Rover.state_machines[:arm]
    drive = Rover.state_machines[:drive]
    transitions = {
      arm: arm.events[:unfold].transition_for(rover),
      drive: drive.events[:roll].transition_for(rover)
    }
    transitions = transitions.slice(only) if only

    arm.create_async_transition_collection(transitions.values)
  end
end
