require_relative '../../files/models/vehicle'

class Motorcycle < Vehicle
  def self.example_class_method(args={})
  end

  state_machine initial: :idling do
    state :first_gear do
      def decibels
        1.0
      end

      example_class_method
    end
  end
end
