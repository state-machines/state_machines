# frozen_string_literal: true

module StateMachines
  module AsyncMode
    # Thread-safe state operations for async-enabled state machines
    # Uses concurrent-ruby for enterprise-grade thread safety
    module ThreadSafeState
      # Gets or creates a reentrant mutex for thread-safe state operations on an object
      # Each object gets its own mutex to avoid global locking
      # Uses Concurrent::ReentrantReadWriteLock for better performance
      def state_machine_mutex
        @_state_machine_mutex ||= Concurrent::ReentrantReadWriteLock.new
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

      # Handle marshalling by excluding the mutex (will be recreated when needed)
      def marshal_dump
        # Get instance variables excluding the mutex
        vars = instance_variables.reject { |var| var == :@_state_machine_mutex }
        vars.map { |var| [var, instance_variable_get(var)] }
      end

      # Restore marshalled object, mutex will be lazily recreated when needed
      def marshal_load(data)
        data.each do |var, value|
          instance_variable_set(var, value)
        end
        # Don't set @_state_machine_mutex - let it be lazily created
      end
    end
  end
end
