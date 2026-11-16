# frozen_string_literal: true

require 'test_helper'

# TransitionCollection#perform claims the attributes of machines that claim
# their transitions (Machine#claims_transitions?), so concurrent performs out
# of one state perform it once. Runs on threads: no extension needed.
class TransitionCollectionWithClaimsTest < StateMachinesTest
  CALLERS = 4
  RELEASE_DELAY = 0.03
  HANDOFF_TIMEOUT = 1
  FAULT_TAG = :transition_claim_fault

  module ClaimingMachine
    def claims_transitions?
      true
    end
  end

  class CargoBay
    attr_accessor :drops

    state_machine :bay, initial: :loaded do
      extend ClaimingMachine

      event(:release) { transition loaded: :empty }

      before_transition(on: :release) { sleep RELEASE_DELAY }
      after_transition(on: :release) { |bay| bay.drops += 1 }
    end
  end

  class OpenBay
    state_machine :bay, initial: :loaded do
      event(:release) { transition loaded: :empty }
    end
  end

  class Satellite
    attr_accessor :launches, :deploys

    state_machine :orbit, initial: :parked do
      extend ClaimingMachine

      event(:launch) { transition parked: :cruising }

      before_transition(on: :launch) { sleep RELEASE_DELAY }
      after_transition(on: :launch) { |satellite| satellite.launches += 1 }
    end

    state_machine :antenna, initial: :stowed do
      extend ClaimingMachine

      event(:deploy) { transition stowed: :extended }

      after_transition(on: :deploy) { |satellite| satellite.deploys += 1 }
    end
  end

  class Rover
    attr_accessor :arm_callbacks, :driving, :resume_drive

    state_machine :arm, initial: :folded do
      extend ClaimingMachine

      event(:unfold) { transition folded: :open }

      before_transition(on: :unfold) { |rover| rover.arm_callbacks += 1 }
    end

    state_machine :drive, initial: :idle do
      extend ClaimingMachine

      event(:roll) { transition idle: :rolling }

      before_transition(on: :roll) do |rover|
        rover.driving.push(:claimed)
        rover.resume_drive.pop(timeout: HANDOFF_TIMEOUT)
      end
    end
  end

  class Lander
    attr_accessor :trail

    state_machine :legs, initial: :stowed do
      extend ClaimingMachine

      event(:extend_legs) { transition stowed: :down }
      event(:ping) { transition all => same }

      before_transition(on: :extend_legs) do |lander|
        lander.trail << lander.legs
        lander.trail << lander.ping
      end
    end
  end

  class SensorFault < StandardError; end

  class Probe
    attr_accessor :fault

    state_machine :alpha, initial: :ready do
      extend ClaimingMachine

      event(:advance_alpha) { transition ready: :done }
    end

    state_machine :beta, initial: :stowed do
      extend ClaimingMachine

      event(:advance_beta) { transition stowed: :extended }
    end

    def beta
      raise SensorFault if @fault == :raise

      throw FAULT_TAG if @fault == :throw

      super
    end
  end

  class Relay
    state_machine :coil, initial: :cold do
      extend ClaimingMachine

      event(:engage) { transition cold: :live }
    end
  end

  class Airlock
    attr_accessor :relay, :armed, :lock_held

    state_machine :door, initial: :sealed do
      extend ClaimingMachine

      event(:cycle) { transition sealed: :cycling }
    end

    def door
      if @armed
        @armed = false
        @lock_held = StateMachines::TransitionClaim::LOCK.owned?
        @relay.engage
      end

      super
    end
  end

  def setup
    @bay = CargoBay.new
    @bay.drops = 0
  end

  def test_a_machine_that_does_not_claim_is_granted_an_empty_set
    bay = OpenBay.new
    transition = OpenBay.state_machines[:bay].events[:release].transition_for(bay)

    assert_empty StateMachines::TransitionClaim.claim([transition])
    refute bay.instance_variable_defined?(StateMachines::TransitionClaim::CLAIMS_VARIABLE)
  end

  # Bug: a copy shared the original's claims, so the two objects saw each
  # other's claims.
  def test_a_copy_gets_its_own_claims
    @bay.release

    [@bay.dup, @bay.clone].each do |copy|
      refute copy.instance_variable_defined?(StateMachines::TransitionClaim::CLAIMS_VARIABLE)
    end
  end

  def test_one_way_transition_is_performed_once_across_threads
    collections = CALLERS.times.map { release_collection }
    results = collections.map { |collection| Thread.new { collection.perform } }.map(&:value)

    assert_equal 1, results.count(true)
    assert_equal CALLERS - 1, results.count(false)
    assert_equal 'empty', @bay.bay
    assert_equal 1, @bay.drops
  end

  def test_concurrent_refusals_are_contended
    collections = CALLERS.times.map { release_collection }
    collections.map { |collection| Thread.new { collection.perform } }.each(&:join)

    refusals = collections.map { |collection| collection.first.refusal }

    assert_equal [nil], refusals.uniq - [:contended]
    assert_equal CALLERS - 1, refusals.count(:contended)
  end

  def test_a_pair_of_machines_is_performed_once_whichever_order_a_collection_lists_them
    satellite = Satellite.new
    satellite.launches = 0
    satellite.deploys = 0

    collections = CALLERS.times.map { |caller| satellite_collection(satellite, reversed: caller.odd?) }
    results = collections.map { |collection| Thread.new { collection.perform } }.map(&:value)

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

    rolling = Thread.new { rover_collection(rover, only: :drive).perform }

    assert_equal :claimed, rover.driving.pop(timeout: HANDOFF_TIMEOUT)

    refute Thread.new { rover_collection(rover).perform }.value
    assert_equal 'folded', rover.arm
    assert_equal 0, rover.arm_callbacks

    rover.resume_drive.push(:go)

    assert rolling.join(HANDOFF_TIMEOUT), 'the held transition never finished'
    assert rolling.value
    assert rover_collection(rover, only: :arm).perform
    assert_equal 'open', rover.arm
  end

  def test_fire_events_performs_a_one_way_transition_once
    results = CALLERS.times.map { Thread.new { @bay.fire_events(:release) } }.map(&:value)

    assert_equal 1, results.count(true)
    assert_equal CALLERS - 1, results.count(false)
    assert_equal 'empty', @bay.bay
    assert_equal 1, @bay.drops
  end

  def test_a_callback_can_read_the_state_and_fire_another_event
    lander = Lander.new
    lander.trail = []
    machine = Lander.state_machines[:legs]

    assert StateMachines::TransitionCollection.new([machine.events[:extend_legs].transition_for(lander)]).perform
    assert_equal 'stowed', lander.trail.first
    assert_kind_of StateMachines::Transition, lander.trail.last
  end

  def test_an_acquisition_that_raises_strands_none_of_the_claims_it_took
    probe = Probe.new
    collection = probe_collection(probe)
    probe.fault = :raise

    owner = Thread.new do
      assert_raises(SensorFault) { collection.perform }
      Fiber[StateMachines::TransitionClaim::OWNER_KEY]
    end.value

    assert_nil owner
    assert_empty probe.instance_variable_get(StateMachines::TransitionClaim::CLAIMS_VARIABLE)

    probe.fault = nil

    assert probe_collection(probe, only: :alpha).perform
    assert_equal 'done', probe.alpha
  end

  def test_an_acquisition_that_throws_strands_none_of_the_claims_it_took
    probe = Probe.new
    collection = probe_collection(probe)
    probe.fault = :throw

    owner = Thread.new do
      catch(FAULT_TAG) { collection.perform }
      Fiber[StateMachines::TransitionClaim::OWNER_KEY]
    end.value

    assert_nil owner
    assert_empty probe.instance_variable_get(StateMachines::TransitionClaim::CLAIMS_VARIABLE)

    probe.fault = nil

    assert probe_collection(probe, only: :alpha).perform
    assert_equal 'done', probe.alpha
  end

  def test_reading_the_source_state_holds_no_lock_and_can_transition_another_object
    airlock = Airlock.new
    airlock.relay = Relay.new
    machine = Airlock.state_machines[:door]
    collection = StateMachines::TransitionCollection.new([machine.events[:cycle].transition_for(airlock)])
    airlock.armed = true

    assert collection.perform
    assert_equal 'live', airlock.relay.coil
    refute airlock.lock_held
    assert_equal 'cycling', airlock.door
  end

  private

  def release_collection
    machine = CargoBay.state_machines[:bay]

    StateMachines::TransitionCollection.new([machine.events[:release].transition_for(@bay)])
  end

  def satellite_collection(satellite, reversed: false)
    transitions = [
      Satellite.state_machines[:orbit].events[:launch].transition_for(satellite),
      Satellite.state_machines[:antenna].events[:deploy].transition_for(satellite)
    ]
    transitions.reverse! if reversed

    StateMachines::TransitionCollection.new(transitions)
  end

  def rover_collection(rover, only: nil)
    transitions = {
      arm: Rover.state_machines[:arm].events[:unfold].transition_for(rover),
      drive: Rover.state_machines[:drive].events[:roll].transition_for(rover)
    }
    transitions = transitions.slice(only) if only

    StateMachines::TransitionCollection.new(transitions.values)
  end

  def probe_collection(probe, only: nil)
    events = { alpha: :advance_alpha, beta: :advance_beta }
    events = events.slice(only) if only
    transitions = events.map { |attribute, event| Probe.state_machines[attribute].events[event].transition_for(probe) }

    StateMachines::TransitionCollection.new(transitions)
  end
end
