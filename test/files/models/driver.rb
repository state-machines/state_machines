require_relative 'model_base'

class Driver < ModelBase
  state_machine :status, :initial => :parked do
    event :park do
      transition :idling => :parked
    end

    event :ignite do
      transition :parked => :idling
    end
  end
end
