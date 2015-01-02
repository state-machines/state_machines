class AutoShop
  attr_accessor :num_customers

  def initialize
    @num_customers = 0
    super
  end

  state_machine initial: :available do
    after_transition available: any, do: :increment_customers
    after_transition busy: any, do: :decrement_customers

    event :tow_vehicle do
      transition available: :busy
    end

    event :fix_vehicle do
      transition busy: :available
    end
  end

  # Increments the number of customers in service
  def increment_customers
    self.num_customers += 1
  end

  # Decrements the number of customers in service
  def decrement_customers
    self.num_customers -= 1
  end
end
