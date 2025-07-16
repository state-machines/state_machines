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

# Experimental Moroccan ship class for testing guard arguments - RMNS Atlas Monkey! 🇲🇦🐒🚀
class RmnsAtlasMonkey < StarfleetShip
  # Override the engage_warp event to demonstrate emergency override
  state_machine :status do
    event :engage_warp do
      # Emergency override allows warp even if core is unstable
      transition impulse: :warp, if: lambda { |ship, *args|
        ship.send(:warp_core_stable?) || args.include?(:emergency_override)
      }
    end

    # Event with mixed guard types
    event :emergency_warp do
      # Multi-param lambda guard (new behavior) - needs to be first for specificity
      transition impulse: :warp, if: lambda { |_ship, *args|
        # Check if first arg is authorization code and second is :confirmed
        args.length >= 2 && args[0] == 'omega-3-7' && args[1] == :confirmed
      }
      # Symbol guard (existing behavior)
      transition impulse: :warp, if: :warp_core_stable?
      # Single-param lambda guard (existing behavior)
      transition impulse: :warp, if: ->(ship) { ship.captain_on_bridge }
    end
  end

  # Add new weapons event to demonstrate target-specific firing
  state_machine :weapons do
    event :fire_at_target do
      transition targeted: :firing, if: lambda { |ship, target_type, *args|
        case target_type
        when :asteroid
          true # Can always fire at asteroids
        when :enemy_ship
          ship.shields_name == :up # Need shields up for combat
        when :photon_torpedo
          args.include?(:full_spread) # Special firing pattern for torpedoes
        else
          false
        end
      }
    end
  end
end
