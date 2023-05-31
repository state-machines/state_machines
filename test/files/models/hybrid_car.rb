require_relative '../../files/models/vehicle'

class HybridCar < Vehicle
  attr_accessor :propulsion_mode, :driving_profile, :target_year

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
  end

  def go_green(driving_profile = nil)
    self.driving_profile = driving_profile if driving_profile

    super()
  end

  def go_gas(driving_profile:)
    self.driving_profile = driving_profile

    super()
  end

  def go_back_in_time(target_year, driving_profile:)
    self.target_year = target_year
    self.driving_profile = driving_profile

    super()
  end
end
