# frozen_string_literal: true

# This file provides optional async extensions for the Machine class.
# It should only be loaded when async functionality is explicitly requested.

module StateMachines
  class Machine
    # AsyncMode extensions for the Machine class
    # Provides async-aware methods while maintaining backward compatibility
    module AsyncExtensions
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
        if enabled
          begin
            require 'state_machines/async_mode'
            @async_mode_enabled = true

            owner_class.include(StateMachines::AsyncMode::ThreadSafeState)
            owner_class.include(StateMachines::AsyncMode::AsyncEvents)
            extend(StateMachines::AsyncMode::AsyncMachine)

            # Extend events to generate async versions
            events.each do |event|
              event.extend(StateMachines::AsyncMode::AsyncEventExtensions)
            end
          rescue LoadError => e
            # Fallback to sync mode with warning (only once per class)
            unless owner_class.instance_variable_get(:@async_fallback_warned)
              warn <<~WARNING
                ⚠️  #{owner_class.name}: Async mode requested but not available on #{RUBY_ENGINE}.

                #{e.message}

                ⚠️  Falling back to synchronous mode. Results may be unpredictable due to engine limitations.
                For production async support, use MRI Ruby (CRuby) 3.2+
              WARNING
              owner_class.instance_variable_set(:@async_fallback_warned, true)
            end

            @async_mode_enabled = false
          end
        else
          @async_mode_enabled = false
        end

        self
      end

      # Check if this specific machine instance has async mode enabled
      def async_mode_enabled?
        @async_mode_enabled || false
      end

      # Thread-safe version of state reading
      def read_safely(object, attribute, ivar = false)
        object.read_state_safely(self, attribute, ivar)
      end

      # Thread-safe version of state writing
      def write_safely(object, attribute, value, ivar = false)
        object.write_state_safely(self, attribute, value, ivar)
      end

      # Thread-safe callback execution for async operations
      def run_callbacks_safely(type, object, context, transition)
        object.state_machine_mutex.with_write_lock do
          callbacks[type].each { |callback| callback.call(object, context, transition) }
        end
      end
    end

    # Include async extensions by default (but only load AsyncMode when requested)
    include AsyncExtensions
  end
end
