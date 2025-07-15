# frozen_string_literal: true

require_relative 'starfleet_ship'

# Autonomous drone with async capabilities
# Demonstrates async: true parameter for autonomous systems
class AutonomousDrone < StarfleetShip
  attr_accessor :teleporter_status, :teleporter_charge_level, :callback_log, :autonomous_mode

  def initialize(attributes = {})
    attributes = {
      teleporter_status: :offline,
      teleporter_charge_level: 0,
      callback_log: [],
      autonomous_mode: true
    }.merge(attributes)

    attributes.each { |attr, value| send("#{attr}=", value) }
    super
  end

  # Override main status machine to be async (autonomous operation)
  state_machine :status, async: true do
    before_transition any => :flying do |drone|
      drone.callback_log << 'Autonomous flight sequence initiated...'
    end

    after_transition any => :flying do |drone|
      drone.callback_log << 'Drone airborne - autonomous navigation active!'
    end

    event :launch do
      transition docked: :flying
    end

    event :enter_warp do
      transition flying: :warping
    end

    event :exit_warp do
      transition warping: :flying
    end

    event :land do
      transition flying: :docked
    end
  end

  # Teleporter system with async capabilities (takes 1 second to turn on)
  state_machine :teleporter_status, initial: :offline, async: true do
    before_transition offline: :charging do |drone|
      drone.callback_log << 'Initializing quantum teleporter matrix...'
      drone.teleporter_charge_level = 0
    end

    after_transition charging: :ready do |drone|
      drone.callback_log << 'Teleporter matrix stabilized and ready!'
      drone.teleporter_charge_level = 100
    end

    before_transition ready: :teleporting do |drone|
      drone.callback_log << 'Engaging quantum teleportation beam...'
    end

    after_transition teleporting: :ready do |drone|
      drone.callback_log << 'Quantum teleportation sequence complete!'
    end

    event :power_up do
      transition offline: :charging
    end

    event :charge_complete do
      transition charging: :ready
    end

    event :teleport do
      transition ready: :teleporting
    end

    event :teleport_complete do
      transition teleporting: :ready
    end

    event :shutdown do
      transition %i[charging ready teleporting] => :offline
    end
  end

  # Use inherited weapons machine from StarfleetShip (remains sync for safety)
  # The inherited :weapons machine has events: arm, target, fire, reload, stand_down

  # Override shields to be async
  state_machine :shields, async: true do
  end

  # Simulate the 1-second teleporter startup process
  def start_teleporter_sequence
    power_up_teleporter_status!

    # Simulate 1-second startup time for quantum matrix stabilization
    sleep(0.1) # Reduced for testing

    charge_complete_teleporter_status!
  end

  # Perform autonomous teleportation sequence
  def perform_teleportation
    return false unless teleporter_status_ready?

    teleport_teleporter_status!

    # Simulate quantum teleportation process
    sleep(0.05) # Brief teleport time

    teleport_complete_teleporter_status!
    true
  end

  # Autonomous launch sequence using async capabilities
  def autonomous_launch_sequence
    if respond_to?(:fire_event_async)
      fire_event_async(:launch)
    else
      launch!
    end
  end

  # Emergency shutdown for autonomous systems
  def emergency_shutdown
    super # Call StarfleetShip emergency_shutdown
    shutdown_teleporter_status! if teleporter_status_ready? || teleporter_status_charging?
    self.autonomous_mode = false
  end

  # Check if drone is operating autonomously
  def autonomous?
    autonomous_mode
  end
end
