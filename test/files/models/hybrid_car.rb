# frozen_string_literal: true

require_relative 'vehicle'

class HybridCar < Vehicle
  attr_accessor :propulsion_mode, :driving_profile, :target_year, :energy_source, :universe, :destination

  state_machine :propulsion_mode, initial: :gas do
    event :go_green do
      transition electric: :electric
      transition flux_capacitor: :electric
      transition gas: :electric
    end

    event :go_gas do
      transition electric: :gas
      transition flux_capacitor: :gas
      transition gas: :gas
    end

    event :go_back_in_time do
      transition electric: :flux_capacitor
      transition flux_capacitor: :flux_capacitor
      transition gas: :flux_capacitor
    end

    event :teleport do
      transition electric: :teleported
      transition flux_capacitor: :teleported
      transition gas: :teleported
    end
  end

  def go_green(driving_profile = nil)
    self.driving_profile = driving_profile if driving_profile

    super()
  end

  def go_gas(driving_profile:)
    self.driving_profile = driving_profile

    super()
  end

  def go_back_in_time(target_year, _flux_capacitor_setting = {}, driving_profile:)
    self.target_year = target_year
    self.driving_profile = driving_profile

    super()
  end

  def teleport(destination, energy_settings, universe_settings)
    self.destination = destination
    self.energy_source = energy_settings
    self.universe = universe_settings
    super()
  end
end
