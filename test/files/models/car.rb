# frozen_string_literal: true

require_relative 'vehicle'

class Car < Vehicle
  state_machine do
    event :reverse do
      transition %i[parked idling first_gear] => :backing_up
    end

    event :park do
      transition backing_up: :parked
    end

    event :idle do
      transition backing_up: :idling
    end

    event :shift_up do
      transition backing_up: :first_gear
    end
  end
end
