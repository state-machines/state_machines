class ThreadStorage
  class << self
    def store
      Thread.current[:store] ||= []
    end

    def flush!
      Thread.current[:store] = nil
    end
  end

  state_machine :state, initial: :stopped do
    event :start do
      transition stopped: :running
    end

    before_transition do
      ThreadStorage.store << :before_transition
    end

    after_transition do
      ThreadStorage.store << :after_transition
    end

    around_transition do |_, _, block|
      ThreadStorage.store << :before_around_transition
      block.call
      ThreadStorage.store << :after_around_transition
    end
  end

  attr_accessor :state

  def initialize
    super
  end
end
