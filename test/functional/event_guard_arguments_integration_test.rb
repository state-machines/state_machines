# frozen_string_literal: true

require 'test_helper'
require_relative '../files/models/starfleet_ship'

# Integration test for event guard arguments functionality
# Uses the RMNS Atlas Monkey, our brave Moroccan test ship built on vibes and shukrans.
class EventGuardArgumentsIntegrationTest < StateMachinesTest
  include StateMachines::TestHelper

  def setup
    @ship = RmnsAtlasMonkey.new
  end

  def test_event_arguments_allow_emergency_override_in_guards
    # Normal operation: should work when warp core is stable
    @ship.undock
    @ship.warp_core_temperature = 1500  # Stable
    assert_sm_can_transition(@ship, :engage_warp, machine_name: :status)
    assert @ship.engage_warp
    assert_sm_state(@ship, :warp, machine_name: :status)

    # Reset ship
    @ship.drop_to_impulse
    assert_sm_state(@ship, :impulse, machine_name: :status)

    # Unstable core: should fail without override
    @ship.warp_core_temperature = 2000  # Unstable
    assert_sm_cannot_transition(@ship, :engage_warp, machine_name: :status)
    refute @ship.engage_warp
    assert_sm_state(@ship, :impulse, machine_name: :status)

    # Unstable core with emergency override: should succeed
    assert @ship.engage_warp(:emergency_override)
    assert_sm_state(@ship, :warp, machine_name: :status)
  end

  def test_event_arguments_support_conditional_logic_in_guards
    # Setup: arm and target weapons
    @ship.arm_weapons
    @ship.target_weapons

    # Test firing at asteroid (always allowed)
    assert @ship.fire_at_target_weapons(:asteroid)
    assert_sm_state(@ship, :firing, machine_name: :weapons)

    # Reset weapons
    @ship.reload_weapons
    @ship.target_weapons

    # Test firing at enemy ship without shields (should fail)
    # Shields start as :down, so this should fail
    refute @ship.fire_at_target_weapons(:enemy_ship)
    assert_sm_state(@ship, :targeted, machine_name: :weapons)

    # Test firing at enemy ship with shields (should succeed)
    @ship.raise_shields
    assert @ship.fire_at_target_weapons(:enemy_ship)
    assert_sm_state(@ship, :firing, machine_name: :weapons)

    # Reset weapons
    @ship.reload_weapons
    @ship.target_weapons

    # Test photon torpedo without full spread (should fail)
    refute @ship.fire_at_target_weapons(:photon_torpedo)
    assert_sm_state(@ship, :targeted, machine_name: :weapons)

    # Test photon torpedo with full spread (should succeed)
    assert @ship.fire_at_target_weapons(:photon_torpedo, :full_spread)
    assert_sm_state(@ship, :firing, machine_name: :weapons)
  end

  def test_backward_compatibility_with_existing_guards
    # Use the original StarfleetShip to verify existing guards still work
    original_ship = StarfleetShip.new
    original_ship.undock
    original_ship.warp_core_temperature = 1500  # Stable

    # The existing warp_core_stable? guard should still work
    assert_sm_can_transition(original_ship, :engage_warp, machine_name: :status)
    assert original_ship.engage_warp
    assert_sm_state(original_ship, :warp, machine_name: :status)

    original_ship.drop_to_impulse
    original_ship.warp_core_temperature = 2000  # Unstable

    # Should fail when core is unstable
    assert_sm_cannot_transition(original_ship, :engage_warp, machine_name: :status)
    refute original_ship.engage_warp
    assert_sm_state(original_ship, :impulse, machine_name: :status)
  end

  def test_mixed_guard_types_with_and_without_event_arguments
    @ship.undock

    # Test symbol guard path
    @ship.warp_core_temperature = 1500
    assert @ship.emergency_warp
    assert_sm_state(@ship, :warp, machine_name: :status)

    # Reset
    @ship.drop_to_impulse
    @ship.warp_core_temperature = 2000

    # Test single-param lambda guard path
    @ship.captain_on_bridge = true
    assert @ship.emergency_warp
    assert_sm_state(@ship, :warp, machine_name: :status)

    # Reset
    @ship.drop_to_impulse
    @ship.captain_on_bridge = false

    # Test multi-param lambda guard path (should fail without proper args)
    refute @ship.emergency_warp("wrong-code")
    assert_sm_state(@ship, :impulse, machine_name: :status)

    # Test multi-param lambda guard path (should succeed with proper args)
    assert @ship.emergency_warp("omega-3-7", :confirmed)
    assert_sm_state(@ship, :warp, machine_name: :status)
  end
end
