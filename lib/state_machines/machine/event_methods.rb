# frozen_string_literal: true

module StateMachines
  class Machine
    module EventMethods
      # Checks if the given value is a matcher (either legacy Matcher class or Data.define matcher)
      def matcher?(value)
        value.is_a?(Matcher) || 
          value.is_a?(WhitelistMatcher) || 
          value.is_a?(BlacklistMatcher) ||
          (value.respond_to?(:matches?) && value.respond_to?(:values))
      end
      # Defines one or more events for the machine and the transitions that can
      # be performed when those events are run.
      def event(*names, &)
        options = names.last.is_a?(Hash) ? names.pop : {}
        StateMachines::OptionsValidator.assert_valid_keys!(options, :human_name)

        # Store the context so that it can be used for / matched against any event
        # that gets added
        @events.context(names, &) if block_given?

        if matcher?(names.first)
          # Add any events referenced in the matcher.  When matchers are used,
          # events are not allowed to be configured.
          raise ArgumentError, "Cannot configure events when using matchers (using #{options.inspect})" if options.any?

          events = add_events(names.first.values)
        else
          events = add_events(names)

          # Update the configuration for the event(s)
          events.each do |event|
            event.human_name = options[:human_name] if options.include?(:human_name)

            # Add any states that may have been referenced within the event
            add_states(event.known_states)
          end
        end

        events.length == 1 ? events.first : events
      end

      alias on event

      # Creates a new transition that determines what to change the current state
      # to when an event fires.
      def transition(options)
        raise ArgumentError, 'Must specify :on event' unless options[:on]

        branches = []
        options = options.dup
        event(*Array(options.delete(:on))) { branches << transition(options) }

        branches.length == 1 ? branches.first : branches
      end

      # Gets the list of all possible transition paths from the current state to
      # the given target state.  If multiple target states are provided, then
      # this will return all possible paths to those states.
      def paths_for(object, requirements = {})
        PathCollection.new(object, self, requirements)
      end
    end
  end
end
