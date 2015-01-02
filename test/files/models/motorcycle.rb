require_relative '../../files/models/vehicle'

class Motorcycle < Vehicle
  state_machine initial: :idling do
    state :first_gear do
      def decibels
        1.0
      end
    end
  end
end
