# frozen_string_literal: true

require 'test_helper'
require 'files/models/starfleet_ship'

class StarfleetShipTest < StateMachinesTest
  def setup
    @ship = StarfleetShip.new
  end

  # Test initial states across all state machines
  def test_should_be_in_initial_states
    assert_sm_state(@ship, :docked, machine_name: :status)
    assert_sm_state(@ship, :down, machine_name: :shields)
    assert_sm_state(@ship, :standby, machine_name: :weapons)
  end

  # Test single state machine transitions
  def test_should_allow_undocking
    assert_sm_transition(@ship, :undock, :impulse, machine_name: :status)
  end

  def test_should_allow_raising_shields
    assert_sm_transition(@ship, :raise_shields, :up, machine_name: :shields)
  end

  def test_should_allow_arming_weapons
    assert_sm_transition(@ship, :arm_weapons, :armed, machine_name: :weapons)
  end

  # Test transition capabilities across different machines
  def test_should_not_allow_warp_when_docked
    assert_sm_cannot_transition(@ship, :engage_warp)
  end

  def test_should_allow_lowering_shields_when_up
    @ship.raise_shields!

    assert_sm_can_transition(@ship, :lower_shields, machine_name: :shields)
  end

  def test_should_allow_weapons_targeting_when_armed
    @ship.arm_weapons!

    assert_sm_can_transition(@ship, :target_weapons, machine_name: :weapons)
  end

  # Test callback definitions across multiple machines
  def test_should_have_departure_checklist_callback
    assert_before_transition(StarfleetShip, from: :docked, do: :departure_checklist)
  end

  def test_should_have_battle_stations_callback
    assert_after_transition(StarfleetShip, on: :red_alert, do: :sound_battle_stations)
  end

  def test_should_have_shield_power_up_callback
    # Test on shields machine specifically
    shields_machine = StarfleetShip.state_machine(:shields)

    assert_before_transition(shields_machine, from: :down, to: :up, do: :power_up_shields)
  end

  def test_should_have_weapons_arming_callback
    # Test on weapons machine specifically
    weapons_machine = StarfleetShip.state_machine(:weapons)

    assert_before_transition(weapons_machine, from: :standby, do: :arm_weapons_systems)
  end

  # Test indirect event triggering across multiple machines
  def test_engage_combat_mode_should_trigger_multiple_events
    @ship.undock! # Get ship ready for combat

    # This method should trigger events on multiple state machines
    assert_sm_triggers_event(@ship, :red_alert, machine_name: :status) do
      @ship.engage_combat_mode
    end
  end

  def test_engage_combat_mode_should_trigger_shield_events
    @ship.undock!  # Get ship ready for combat

    assert_sm_triggers_event(@ship, :raise_shields, machine_name: :shields) do
      @ship.engage_combat_mode
    end
  end

  def test_engage_combat_mode_should_trigger_weapons_events
    @ship.undock!  # Get ship ready for combat

    assert_sm_triggers_event(@ship, :arm, machine_name: :weapons) do
      @ship.engage_combat_mode
    end
  end

  # Test complex multi-machine scenarios
  def test_emergency_shutdown_affects_all_systems
    # Set up ship in active state
    @ship.undock!
    @ship.raise_shields!
    @ship.arm_weapons!

    # Verify active states
    assert_sm_state(@ship, :impulse, machine_name: :status)
    assert_sm_state(@ship, :up, machine_name: :shields)
    assert_sm_state(@ship, :armed, machine_name: :weapons)

    # Emergency shutdown should affect multiple systems
    @ship.emergency_shutdown

    assert_sm_state(@ship, :emergency, machine_name: :status)
    assert_sm_state(@ship, :down, machine_name: :shields)
    assert_sm_state(@ship, :standby, machine_name: :weapons)
  end

  def test_battle_sequence_coordination
    @ship.undock!

    # Test coordinated battle preparation
    @ship.begin_battle_sequence

    assert_sm_state(@ship, :up, machine_name: :shields)
    assert_sm_state(@ship, :targeted, machine_name: :weapons)
  end

  # Test state machine specific event triggering
  def test_shield_modulation_self_transition
    @ship.raise_shields!

    # For self-transitions, we test that the event can be triggered, not that state changes
    assert_sm_can_transition(@ship, :modulate, machine_name: :shields)
    @ship.modulate!

    assert_sm_state(@ship, :up, machine_name: :shields) # Should remain up after modulation
  end

  def test_weapons_fire_sequence
    @ship.arm_weapons!
    @ship.target_weapons!

    # The fire_all_weapons method triggers both fire and reload events
    assert_sm_triggers_event(@ship, %i[fire reload], machine_name: :weapons) do
      @ship.fire_all_weapons
    end
  end

  # Test persisted states (if persistence is implemented)
  def test_should_persist_multiple_machine_states
    @ship.undock!
    @ship.raise_shields!
    @ship.arm_weapons!

    # Test persistence for each machine (assuming persistence is enabled)
    assert_sm_state_persisted(@ship, 'impulse', :status)
    assert_sm_state_persisted(@ship, 'up', :shields)
    assert_sm_state_persisted(@ship, 'armed', :weapons)
  end

  # Test callback execution verification
  def test_warp_core_engagement_callback_executes
    @ship.undock!
    initial_temp = @ship.warp_core_temperature

    @ship.engage_warp!

    assert_operator @ship.warp_core_temperature, :>, initial_temp,
                    'Expected warp core temperature to increase'
  end

  def test_red_alert_callback_executes
    @ship.undock!

    refute @ship.red_alert_triggered

    @ship.red_alert!

    assert @ship.red_alert_triggered, 'Expected red alert to be triggered'
  end
end
