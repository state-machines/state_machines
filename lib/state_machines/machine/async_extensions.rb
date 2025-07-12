# frozen_string_literal: true

# This file provides optional async extensions for the Machine class.
# It should only be loaded when async functionality is explicitly requested.

module StateMachines
  class Machine
    # AsyncMode extensions for the Machine class
    # Provides async-aware methods while maintaining backward compatibility
    module AsyncExtensions
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # Enable async support for all machines created by this class
        # This adds thread-safe state operations to objects
        def enable_async_support!
          # Load async support only when explicitly requested
          require 'state_machines/async_mode'

          @async_enabled = true

          # Extend owner class with async capabilities when machines are created
          prepend(AsyncMachineExtensions)
        end

        # Check if async support is enabled globally
        def async_enabled?
          @async_enabled || false
        end
      end

      # Instance methods added to Machine for async support

      # Configure this specific machine instance for async mode
      #
      # Example:
      #   class Vehicle
      #     state_machine initial: :parked do
      #       configure_async_mode! # Enable async for this machine
      #
      #       event :ignite do
      #         transition parked: :idling
      #       end
      #     end
      #   end
      def configure_async_mode!(enabled = true)
        require 'state_machines/async_mode' if enabled
        @async_mode_enabled = enabled

        if enabled && !owner_class.include?(StateMachines::AsyncMode::ThreadSafeState)
          owner_class.include(StateMachines::AsyncMode::ThreadSafeState)
          owner_class.include(StateMachines::AsyncMode::AsyncEvents)
          self.extend(StateMachines::AsyncMode::AsyncMachine)

          # Extend events to generate async versions
          events.each do |event|
            event.extend(StateMachines::AsyncMode::AsyncEventExtensions)
          end
        end

        self
      end

      # Check if this specific machine instance has async mode enabled
      def async_mode_enabled?
        @async_mode_enabled || false
      end

      # Thread-safe version of state reading
      def read_safely(object, attribute, ivar = false)
        if async_mode_enabled? && object.respond_to?(:read_state_safely)
          object.read_state_safely(self, attribute, ivar)
        else
          read(object, attribute, ivar)
        end
      end

      # Thread-safe version of state writing
      def write_safely(object, attribute, value, ivar = false)
        if async_mode_enabled? && object.respond_to?(:write_state_safely)
          object.write_state_safely(self, attribute, value, ivar)
        else
          write(object, attribute, value, ivar)
        end
      end

      # Thread-safe callback execution for async operations
      def run_callbacks_safely(type, object, context, transition)
        if async_mode_enabled? && object.respond_to?(:state_machine_mutex)
          object.state_machine_mutex.synchronize do
            callbacks[type].each { |callback| callback.call(object, context, transition) }
          end
        else
          callbacks[type].each { |callback| callback.call(object, context, transition) }
        end
      end
    end

    # Extensions that get prepended to Machine class when async is enabled globally
    module AsyncMachineExtensions
      # Override initialize to add async capabilities to owner class
      def initialize(owner_class, *args, **kwargs)
        result = super(owner_class, *args, **kwargs)

        # Only add async capabilities if AsyncMode module is loaded and global async is enabled
        if self.class.async_enabled? && defined?(StateMachines::AsyncMode)
          # Add async capabilities to the owner class if not already present
          unless owner_class.include?(StateMachines::AsyncMode::ThreadSafeState)
            owner_class.include(StateMachines::AsyncMode::ThreadSafeState)
          end

          unless owner_class.include?(StateMachines::AsyncMode::AsyncEvents)
            owner_class.include(StateMachines::AsyncMode::AsyncEvents)
          end

          # Enable async mode for this machine by default
          configure_async_mode!(true)
        end

        result
      end

      # Thread-safe state initialization for async-enabled machines
      def initialize_state(object, options = {})
        if async_mode_enabled? && object.respond_to?(:state_machine_mutex)
          object.state_machine_mutex.synchronize do
            super(object, options)
          end
        else
          super(object, options)
        end
      end
    end

    # Include async extensions by default (but only load AsyncMode when requested)
    include AsyncExtensions
  end
end
