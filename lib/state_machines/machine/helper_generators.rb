# frozen_string_literal: true

module StateMachines
  class Machine
    module HelperGenerators
      protected

      # Adds helper methods for interacting with the state machine, including
      # for states, events, and transitions
      def define_helpers
        define_state_accessor
        define_state_predicate
        define_event_helpers
        define_path_helpers
        define_action_helpers if define_action_helpers?
        define_name_helpers
      end

      # Defines the initial values for state machine attributes.  Static values
      # are set prior to the original initialize method and dynamic values are
      # set *after* the initialize method in case it is dependent on it.
      def define_state_initializer
        define_helper :instance, <<-END_EVAL, __FILE__, __LINE__ + 1
            def initialize(*)
              self.class.state_machines.initialize_states(self) { super }
            end
        END_EVAL
      end

      # Adds reader/writer methods for accessing the state attribute
      def define_state_accessor
        attribute = self.attribute

        @helper_modules[:instance].class_eval { attr_reader attribute } unless owner_class_ancestor_has_method?(:instance, attribute)
        @helper_modules[:instance].class_eval { attr_writer attribute } unless owner_class_ancestor_has_method?(:instance, "#{attribute}=")
      end

      # Adds predicate method to the owner class for determining the name of the
      # current state
      def define_state_predicate
        call_super = owner_class_ancestor_has_method?(:instance, "#{name}?") ? true : false
        define_helper :instance, <<-END_EVAL, __FILE__, __LINE__ + 1
            def #{name}?(*args)
              args.empty? && (#{call_super} || defined?(super)) ? super : self.class.state_machine(#{name.inspect}).states.matches?(self, *args)
            end
        END_EVAL
      end

      # Adds helper methods for getting information about this state machine's
      # events
      def define_event_helpers
        # Gets the events that are allowed to fire on the current object
        define_helper(:instance, attribute(:events)) do |machine, object, *args|
          machine.events.valid_for(object, *args).map(&:name)
        end

        # Gets the next possible transitions that can be run on the current
        # object
        define_helper(:instance, attribute(:transitions)) do |machine, object, *args|
          machine.events.transitions_for(object, *args)
        end

        # Fire an arbitrary event for this machine
        define_helper(:instance, "fire_#{attribute(:event)}") do |machine, object, event, *args|
          machine.events.fetch(event).fire(object, *args)
        end

        # Add helpers for tracking the event / transition to invoke when the
        # action is called
        return unless action

        event_attribute = attribute(:event)
        define_helper(:instance, event_attribute) do |machine, object|
          # Interpret non-blank events as present
          event = machine.read(object, :event, true)
          event && !(event.respond_to?(:empty?) && event.empty?) ? event.to_sym : nil
        end

        # A roundabout way of writing the attribute is used here so that
        # integrations can hook into this modification
        define_helper(:instance, "#{event_attribute}=") do |machine, object, value|
          machine.write(object, :event, value, true)
        end

        event_transition_attribute = attribute(:event_transition)
        define_helper :instance, <<-END_EVAL, __FILE__, __LINE__ + 1
              protected; attr_accessor #{event_transition_attribute.inspect}
        END_EVAL
      end

      # Adds helper methods for getting information about this state machine's
      # available transition paths
      def define_path_helpers
        # Gets the paths of transitions available to the current object
        define_helper(:instance, attribute(:paths)) do |machine, object, *args|
          machine.paths_for(object, *args)
        end
      end

      # Adds helper methods for accessing naming information about states and
      # events on the owner class
      def define_name_helpers
        # Gets the humanized version of a state
        define_helper(:class, "human_#{attribute(:name)}") do |machine, klass, state|
          machine.states.fetch(state).human_name(klass)
        end

        # Gets the humanized version of an event
        define_helper(:class, "human_#{attribute(:event_name)}") do |machine, klass, event|
          machine.events.fetch(event).human_name(klass)
        end

        # Gets the state name for the current value
        define_helper(:instance, attribute(:name)) do |machine, object|
          machine.states.match!(object).name
        end

        # Gets the human state name for the current value
        define_helper(:instance, "human_#{attribute(:name)}") do |machine, object|
          machine.states.match!(object).human_name(object.class)
        end
      end
    end
  end
end
