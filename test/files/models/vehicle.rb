require_relative 'model_base'
require_relative 'auto_shop'

class Vehicle < ModelBase
  attr_accessor :auto_shop, :seatbelt_on, :insurance_premium, :force_idle, :callbacks, :saved, :time_elapsed, :last_transition_args

  def initialize(attributes = {})
    attributes = {
      auto_shop: AutoShop.new,
      seatbelt_on: false,
      insurance_premium: 50,
      force_idle: false,
      callbacks: [],
      saved: false
    }.merge(attributes)

    attributes.each { |attr, value| send("#{attr}=", value) }
    super()
  end

  # Defines the state machine for the state of the vehicled
  state_machine initial: ->(vehicle) { vehicle.force_idle ? :idling : :parked }, action: :save do
    before_transition { |vehicle, transition| vehicle.last_transition_args = transition.args }
    before_transition parked: any, do: :put_on_seatbelt
    before_transition any => :stalled, :do => :increase_insurance_premium
    after_transition any => :parked, :do => lambda { |vehicle| vehicle.seatbelt_on = false }
    after_transition on: :crash, do: :tow
    after_transition on: :repair, do: :fix

    # Callback tracking for initial state callbacks
    after_transition any => :parked, :do => ->(vehicle) { vehicle.callbacks << 'before_enter_parked' }
    before_transition any => :idling, :do => ->(vehicle) { vehicle.callbacks << 'before_enter_idling' }

    around_transition do |vehicle, _transition, block|
      time = Time.now
      block.call
      vehicle.time_elapsed = Time.now - time
    end

    event all do
      transition locked: :parked
    end

    event :park do
      transition [:idling, :first_gear] => :parked
    end

    event :ignite do
      transition stalled: :stalled
      transition parked: :idling
    end

    event :idle do
      transition first_gear: :idling
    end

    event :shift_up do
      transition idling: :first_gear, first_gear: :second_gear, second_gear: :third_gear
    end

    event :shift_down do
      transition third_gear: :second_gear
      transition second_gear: :first_gear
    end

    event :crash do
      transition [:first_gear, :second_gear, :third_gear] => :stalled, :if => ->(vehicle) { vehicle.auto_shop.available? }
    end

    event :repair do
      transition stalled: :parked, if: :auto_shop_busy?
    end
  end

  state_machine :insurance_state, initial: :inactive, namespace: 'insurance' do
    event :buy do
      transition inactive: :active
    end

    event :cancel do
      transition active: :inactive
    end
  end

  def save
    super
  end

  def new_record?
    @saved == false
  end

  def park
    super
  end

  # Tows the vehicle to the auto shop
  def tow
    auto_shop.tow_vehicle
  end

  # Fixes the vehicle; it will no longer be in the auto shop
  def fix
    auto_shop.fix_vehicle
  end

  def decibels
    0.0
  end

  private

  # Safety first! Puts on our seatbelt
  def put_on_seatbelt
    self.seatbelt_on = true
  end

  # We crashed! Increase the insurance premium on the vehicle
  def increase_insurance_premium
    self.insurance_premium += 100
  end

  # Is the auto shop currently servicing another customer?
  def auto_shop_busy?
    auto_shop.busy?
  end
end
