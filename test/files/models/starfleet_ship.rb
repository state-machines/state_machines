# frozen_string_literal: true

require_relative 'model_base'

class StarfleetShip < ModelBase
  attr_accessor :warp_core_temperature, :shield_strength, :crew_count, :captain_on_bridge, :red_alert_triggered, :emergency_protocols_active, :docking_sequence_complete

  def initialize(attributes = {})
    attributes = {
      warp_core_temperature: 1000,
      shield_strength: 100,
      crew_count: 430,
      captain_on_bridge: true,
      red_alert_triggered: false,
      emergency_protocols_active: false,
      docking_sequence_complete: false
    }.merge(attributes)

    attributes.each { |attr, value| send("#{attr}=", value) }
    super()
  end

  # Main ship status state machine
  state_machine :status, initial: :docked do
    before_transition docked: any, do: :departure_checklist
    before_transition any => :warp, do: :engage_warp_core
    after_transition on: :red_alert, do: :sound_battle_stations
    after_transition on: :all_clear, do: :stand_down_alert
    after_transition any => :docked, do: :shutdown_warp_core

    event :undock do
      transition docked: :impulse
    end

    event :engage_warp do
      transition impulse: :warp, if: :warp_core_stable?
    end

    event :drop_to_impulse do
      transition warp: :impulse
    end

    event :dock do
      transition impulse: :docked
    end

    event :red_alert do
      transition %i[impulse warp] => :battle_stations
    end

    event :all_clear do
      transition battle_stations: :impulse
    end

    event :emergency_stop do
      transition %i[warp impulse] => :emergency
    end
  end

  # Shield system state machine
  state_machine :shields, initial: :down do
    before_transition down: :up, do: :power_up_shields
    after_transition up: :down, do: :reroute_power
    after_transition on: :modulate, do: :adjust_frequency

    event :raise_shields do
      transition down: :up
    end

    event :lower_shields do
      transition up: :down
    end

    event :modulate do
      transition up: :up # Self-transition to adjust frequency
    end

    event :overload do
      transition up: :down
    end
  end

  # Weapons system state machine
  state_machine :weapons, initial: :standby, namespace: 'weapons' do
    before_transition standby: any, do: :arm_weapons_systems
    after_transition on: :fire, do: :log_weapons_discharge
    after_transition on: :target, do: :lock_onto_target

    event :arm do
      transition standby: :armed
    end

    event :target do
      transition armed: :targeted
    end

    event :fire do
      transition targeted: :firing
    end

    event :reload do
      transition firing: :armed
    end

    event :stand_down do
      transition %i[armed targeted firing] => :standby
    end
  end

  # Custom methods that can trigger events indirectly
  def engage_combat_mode
    red_alert!
    raise_shields!
    arm_weapons!
  end

  def emergency_shutdown
    emergency_stop!
    lower_shields!
    stand_down_weapons!
  end

  def begin_battle_sequence
    if shields_down? || weapons_standby?
      raise_shields!
      arm_weapons!
    end
    target_weapons!
  end

  # Helper method for shield state
  def shields_down?
    shields_name == :down
  end

  # Fire all weapons (triggers multiple events)
  def fire_all_weapons
    fire_weapons! if weapons_targeted?
    reload_weapons! if weapons_firing?
  end

  private

  def departure_checklist
    # Pre-flight checks
  end

  def engage_warp_core
    self.warp_core_temperature += 500
  end

  def shutdown_warp_core
    self.warp_core_temperature = 1000
  end

  def sound_battle_stations
    self.red_alert_triggered = true
  end

  def stand_down_alert
    self.red_alert_triggered = false
  end

  def power_up_shields
    # Shield activation sequence
  end

  def reroute_power
    # Power management
  end

  def adjust_frequency
    # Shield modulation
  end

  def arm_weapons_systems
    # Weapons activation
  end

  def log_weapons_discharge
    # Tactical log entry
  end

  def lock_onto_target
    # Targeting computer engagement
  end

  def warp_core_stable?
    warp_core_temperature < 1800
  end
end
