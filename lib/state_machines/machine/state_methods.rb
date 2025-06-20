# frozen_string_literal: true

module StateMachines
  class Machine
    module StateMethods
      # Checks if the given value is a matcher (either legacy Matcher class or Data.define matcher)
      def matcher?(value)
        value.is_a?(Matcher) || 
          value.is_a?(WhitelistMatcher) || 
          value.is_a?(BlacklistMatcher) ||
          (value.respond_to?(:matches?) && value.respond_to?(:values))
      end
      # Gets the initial state of the machine for the given object. If a dynamic
      # initial state was configured for this machine, then the object will be
      # passed into the lambda block to help determine the actual state.
      def initial_state(object)
        states.fetch(dynamic_initial_state? ? evaluate_method(object, @initial_state) : @initial_state) if instance_variable_defined?(:@initial_state)
      end

      # Whether a dynamic initial state is being used in the machine
      def dynamic_initial_state?
        instance_variable_defined?(:@initial_state) && @initial_state.is_a?(Proc)
      end

      # Initializes the state on the given object.  Initial values are only set if
      # the machine's attribute hasn't been previously initialized.
      #
      # Configuration options:
      # * <tt>:force</tt> - Whether to initialize the state regardless of its
      #   current value
      # * <tt>:to</tt> - A hash to set the initial value in instead of writing
      #   directly to the object
      def initialize_state(object, options = {})
        state = initial_state(object)
        return unless state && (options[:force] || initialize_state?(object))

        value = state.value

        if (hash = options[:to])
          hash[attribute.to_s] = value
        else
          write(object, :state, value)
        end
      end

      # Customizes the definition of one or more states in the machine.
      def state(*names, &)
        options = names.last.is_a?(Hash) ? names.pop : {}
        StateMachines::OptionsValidator.assert_valid_keys!(options, :value, :cache, :if, :human_name)

        # Store the context so that it can be used for / matched against any state
        # that gets added
        @states.context(names, &) if block_given?

        if matcher?(names.first)
          # Add any states referenced in the matcher.  When matchers are used,
          # states are not allowed to be configured.
          raise ArgumentError, "Cannot configure states when using matchers (using #{options.inspect})" if options.any?

          states = add_states(names.first.values)
        else
          states = add_states(names)

          # Update the configuration for the state(s)
          states.each do |state|
            if options.include?(:value)
              state.value = options[:value]
              self.states.update(state)
            end

            state.human_name = options[:human_name] if options.include?(:human_name)
            state.cache = options[:cache] if options.include?(:cache)
            state.matcher = options[:if] if options.include?(:if)
          end
        end

        states.length == 1 ? states.first : states
      end

      alias other_states state

      # Gets the current value stored in the given object's attribute.
      def read(object, attribute, ivar = false)
        attribute = self.attribute(attribute)
        if ivar
          object.instance_variable_defined?(:"@#{attribute}") ? object.instance_variable_get("@#{attribute}") : nil
        else
          object.send(attribute)
        end
      end

      # Sets a new value in the given object's attribute.
      def write(object, attribute, value, ivar = false)
        attribute = self.attribute(attribute)
        ivar ? object.instance_variable_set(:"@#{attribute}", value) : object.send("#{attribute}=", value)
      end

      protected

      # Determines if the machine's attribute needs to be initialized.  This
      # will only be true if the machine's attribute is blank.
      def initialize_state?(object)
        value = read(object, :state)
        (value.nil? || (value.respond_to?(:empty?) && value.empty?)) && !states[value, :value]
      end
    end
  end
end
