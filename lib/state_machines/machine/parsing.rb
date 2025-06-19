# frozen_string_literal: true

module StateMachines
  class Machine
    module Parsing
      private

      # Parses callback arguments for backward compatibility with both positional
      # and keyword argument styles. Supports Ruby 3.2+ keyword arguments while
      # maintaining full backward compatibility with the legacy API.
      def parse_callback_arguments(args, options)
        # Handle legacy positional args: before_transition(:method1, :method2, from: :state)
        if args.any?
          # Extract hash options from the end of args if present
          parsed_options = args.last.is_a?(Hash) ? args.pop.dup : {}

          # Merge any additional keyword options
          parsed_options.merge!(options) if options.any?

          # Remaining args become the :do option (method names to call)
          parsed_options[:do] = args if args.any?

          parsed_options
        else
          # Pure keyword argument style: before_transition(from: :state, to: :other, do: :method)
          options.dup
        end
      end

      # Adds a new transition callback of the given type.
      def add_callback(type, options, &)
        callbacks[type == :around ? :before : type] << callback = Callback.new(type, options, &)
        add_states(callback.known_states)
        callback
      end

      # Tracks the given set of states in the list of all known states for
      # this machine
      def add_states(new_states)
        new_states.map do |new_state|
          # Check for other states that use a different class type for their name.
          # This typically prevents string / symbol misuse.
          if new_state && (conflict = states.detect { |state| state.name && state.name.class != new_state.class })
            raise ArgumentError, "#{new_state.inspect} state defined as #{new_state.class}, #{conflict.name.inspect} defined as #{conflict.name.class}; all states must be consistent"
          end

          unless (state = states[new_state])
            states << state = State.new(self, new_state)

            # Copy states over to sibling machines
            sibling_machines.each { |machine| machine.states << state }
          end

          state
        end
      end

      # Tracks the given set of events in the list of all known events for
      # this machine
      def add_events(new_events)
        new_events.map do |new_event|
          # Check for other states that use a different class type for their name.
          # This typically prevents string / symbol misuse.
          if (conflict = events.detect { |event| event.name.class != new_event.class })
            raise ArgumentError, "#{new_event.inspect} event defined as #{new_event.class}, #{conflict.name.inspect} defined as #{conflict.name.class}; all events must be consistent"
          end

          unless (event = events[new_event])
            events << event = Event.new(self, new_event)
          end

          event
        end
      end
    end
  end
end
