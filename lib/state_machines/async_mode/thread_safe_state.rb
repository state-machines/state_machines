# frozen_string_literal: true

module StateMachines
  module AsyncMode
    # Thread-safe state operations for async-enabled state machines
    # Uses concurrent-ruby for enterprise-grade thread safety
    module ThreadSafeState
      # Lazily created concurrency primitives, which are not part of an
      # object's marshalled state
      TRANSIENT_VARIABLES = %i[@_state_machine_mutex @_state_machine_transition_claims].freeze

      # Fiber storage key for the owner of the transitions being performed by
      # the current fiber and the fibers it spawns
      TRANSITION_OWNER_KEY = :state_machines_transition_owner

      MUTEX_CREATION_LOCK = Thread::Mutex.new

      # A granted hold on one machine attribute of one object
      TransitionClaim = Struct.new(:attribute, :owner, :previous_owner, :created)

      # Gets or creates a reentrant mutex for thread-safe state operations on an object
      # Each object gets its own mutex to avoid global locking
      # Uses Concurrent::ReentrantReadWriteLock for better performance
      def state_machine_mutex
        @_state_machine_mutex || MUTEX_CREATION_LOCK.synchronize do
          @_state_machine_mutex ||= Concurrent::ReentrantReadWriteLock.new
        end
      end

      # Thread-safe version of state reading
      # Ensures atomic read operations across concurrent threads
      def read_state_safely(machine, attribute, ivar = false)
        state_machine_mutex.with_read_lock do
          machine.read(self, attribute, ivar)
        end
      end

      # Thread-safe version of state writing
      # Ensures atomic write operations across concurrent threads
      def write_state_safely(machine, attribute, value, ivar = false)
        state_machine_mutex.with_write_lock do
          machine.write(self, attribute, value, ivar)
        end
      end

      # Claims the machine's attribute for a transition out of the given state,
      # returning the claim or nil when another owner already holds it or the
      # object is no longer in that state.
      #
      # A claim is reentrant: the fiber holding it, and the fibers it spawns,
      # are granted nested claims for the same attribute.
      def claim_state_machine_transition(machine, from_name)
        previous_owner = Fiber[TRANSITION_OWNER_KEY]
        owner = previous_owner || Object.new

        claim = state_machine_mutex.with_write_lock do
          claims = (@_state_machine_transition_claims ||= {})
          holder = claims[machine.attribute]

          if holder.nil?
            if machine.states.match!(self).name == from_name
              claims[machine.attribute] = owner
              TransitionClaim.new(machine.attribute, owner, previous_owner, true)
            end
          elsif holder.equal?(owner)
            TransitionClaim.new(machine.attribute, owner, previous_owner, false)
          end
        end

        Fiber[TRANSITION_OWNER_KEY] = owner if claim
        claim
      end

      # Releases a claim granted by #claim_state_machine_transition
      def release_state_machine_transition(claim)
        Fiber[TRANSITION_OWNER_KEY] = claim.previous_owner
        return unless claim.created

        state_machine_mutex.with_write_lock do
          @_state_machine_transition_claims.delete(claim.attribute)
        end
      end

      # Handle marshalling by excluding the mutex (will be recreated when needed)
      def marshal_dump
        vars = instance_variables - TRANSIENT_VARIABLES
        vars.map { |var| [var, instance_variable_get(var)] }
      end

      # Restore marshalled object, mutex will be lazily recreated when needed
      def marshal_load(data)
        data.each do |var, value|
          instance_variable_set(var, value)
        end
      end
    end
  end
end
