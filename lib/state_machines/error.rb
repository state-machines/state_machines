module StateMachines
  # An error occurred during a state machine invocation
  class Error < StandardError
    # The object that failed
    attr_reader :object

    def initialize(object, message = nil) #:nodoc:
      @object = object

      super(message)
    end
  end

  # An invalid integration was specified
  class IntegrationNotFound < Error
    def initialize(name)
      super(nil, "#{name.inspect} is an invalid integration")
    end
  end

  # An invalid integration was registered
  class IntegrationError < StandardError

  end
end
