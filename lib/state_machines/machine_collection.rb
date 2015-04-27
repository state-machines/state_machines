module StateMachines
  # Represents a collection of state machines for a class
  class MachineCollection < Hash
    # Initializes the state of each machine in the given object.  This can allow
    # states to be initialized in two groups: static and dynamic.  For example:
    # 
    #   machines.initialize_states(object) do
    #     # After static state initialization, before dynamic state initialization
    #   end
    # 
    # If no block is provided, then all states will still be initialized.
    # 
    # Valid configuration options:
    # * <tt>:static</tt> - Whether to initialize static states. Unless set to
    #   false, the state will be initialized regardless of its current value.
    #   Default is true.
    # * <tt>:dynamic</tt> - Whether to initialize dynamic states.  If set to
    #   :force, the state will be initialized regardless of its current value.
    #   Default is true.
    # * <tt>:to</tt> - A hash to write the initialized state to instead of
    #   writing to the object.  Default is to write directly to the object.
    def initialize_states(object, options = {}, attributes = {})
      options.assert_valid_keys( :static, :dynamic, :to)
      options = {:static => true, :dynamic => true}.merge(options)

      result = yield if block_given?

      each_value do |machine|
        unless machine.dynamic_initial_state?
          force = options[:static] == :force || !attributes.keys.map(&:to_sym).include?(machine.attribute)
          machine.initialize_state(object, force: force, :to => options[:to])
        end
      end if options[:static]

      each_value do |machine|
        machine.initialize_state(object, :force => options[:dynamic] == :force, :to => options[:to]) if machine.dynamic_initial_state?
      end if options[:dynamic]

      result
    end

    # Runs one or more events in parallel on the given object.  See
    # StateMachines::InstanceMethods#fire_events for more information.
    def fire_events(object, *events)
      run_action = [true, false].include?(events.last) ? events.pop : true

      # Generate the transitions to run for each event
      transitions = events.collect do |event_name|
        # Find the actual event being run
        event = nil
        detect {|name, machine| event = machine.events[event_name, :qualified_name]}

        raise(InvalidEvent.new(object, event_name)) unless event

        # Get the transition that will be performed for the event
        unless transition = event.transition_for(object)
          event.on_failure(object)
        end
        transition
      end.compact

      # Run the events in parallel only if valid transitions were found for
      # all of them
      if events.length == transitions.length
        TransitionCollection.new(transitions, {use_transactions: resolve_use_transactions, actions: run_action}).perform
      else
        false
      end
    end

    # Builds the collection of transitions for all event attributes defined on
    # the given object.  This will only include events whose machine actions
    # match the one specified.
    # 
    # These should only be fired as a result of the action being run.
    def transitions(object, action, options = {})
      transitions = map do |name, machine|
        machine.events.attribute_transition_for(object, true) if machine.action == action
      end

      AttributeTransitionCollection.new(transitions.compact, {use_transactions: resolve_use_transactions}.merge(options))
    end

    protected

    def resolve_use_transactions
      use_transactions = nil
      each_value do |machine|
        # Determine use_transactions setting for this set of transitions.  If from multiple state_machines, the settings must match.
        raise 'Encountered mismatched use_transactions configurations for multiple state_machines' if !use_transactions.nil? && use_transactions != machine.use_transactions
        use_transactions = machine.use_transactions
      end
      use_transactions
    end
  end
end
