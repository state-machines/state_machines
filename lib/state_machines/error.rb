# frozen_string_literal: true

module StateMachines
  # An error occurred during a state machine invocation
  class Error < StandardError
    # The object that failed
    attr_reader :object

    def initialize(object, message = nil) # :nodoc:
      @object = object

      super(message)
    end
  end

  # An invalid integration was specified
  class IntegrationNotFound < Error
    def initialize(name)
      super(nil, "#{name.inspect} is an invalid integration. #{error_message}")
    end

    def valid_integrations
      "Valid integrations are: #{valid_integrations_name}"
    end

    def valid_integrations_name
      Integrations.list.collect(&:integration_name)
    end

    def no_integrations
      'No integrations registered'
    end

    def error_message
      if Integrations.list.size.zero?
        no_integrations
      else
        valid_integrations
      end
    end
  end

  # An invalid integration was registered
  class IntegrationError < StandardError
  end

  # An invalid event was specified
  class InvalidEvent < Error
    # The event that was attempted to be run
    attr_reader :event

    def initialize(object, event_name) # :nodoc:
      @event = event_name

      super(object, "#{event.inspect} is an unknown state machine event")
    end
  end

  # An invalid transition was attempted
  class InvalidTransition < Error
    # The machine attempting to be transitioned
    attr_reader :machine

    # The current state value for the machine
    attr_reader :from

    # Why the transition was refused: the reason recorded for the event on the
    # object when the error was built.
    #
    # @return [:no_transition, :guard, :halted, :action_failed, :contended, nil]
    # @see StateMachines::Event#refusal
    attr_reader :reason

    def initialize(object, machine, event) # :nodoc:
      @machine = machine
      @from_state = machine.states.match!(object)
      @from = machine.read(object, :state)
      @event = machine.events.fetch(event)
      @reason = @event.refusal(object)
      errors = machine.errors_for(object)

      message = "Cannot transition #{machine.name} via :#{self.event} from #{from_name.inspect}"
      message << " (Reason(s): #{errors})" unless errors.empty?
      super(object, message)
    end

    # The event that triggered the failed transition
    def event
      @event.name
    end

    # The fully-qualified name of the event that triggered the failed transition
    def qualified_event
      @event.qualified_name
    end

    # The name for the current state
    def from_name
      @from_state.name
    end

    # The fully-qualified name for the current state
    def qualified_from_name
      @from_state.qualified_name
    end
  end

  # A set of transition failed to run in parallel
  class InvalidParallelTransition < Error
    # The set of events that failed the transition(s)
    attr_reader :events

    # The refusal reason of each event that caused the failure, keyed by the
    # event name as given.  Events refused only because another one was are
    # left out.
    #
    # @return [Hash{Symbol => Symbol}]
    # @see StateMachines::Event#refusal
    attr_reader :reasons

    def initialize(object, events) # :nodoc:
      @events = events
      @reasons = refusal_reasons(object, events)

      super(object, "Cannot run events in parallel: #{events * ', '}")
    end

    private

    # Reads the recorded refusal reason of each given event on the object,
    # finding each event across the object's machines by its qualified name.
    #
    # @param object [Object] the object the events were fired on
    # @param events [Array<Symbol>] the qualified event names that were fired
    # @return [Hash{Symbol => Symbol}] the reason per event name, leaving out
    #   events without one (and every event when the object has no machines)
    def refusal_reasons(object, events)
      return {} unless object.class.respond_to?(:state_machines)

      machines = object.class.state_machines.values
      events.each_with_object({}) do |event_name, reasons|
        event = machines.lazy.filter_map { |machine| machine.events[event_name, :qualified_name] }.first
        reason = event&.refusal(object)
        reasons[event_name] = reason if reason
      end
    end
  end

  # A method was called in an invalid state context
  class InvalidContext < Error
  end
end
