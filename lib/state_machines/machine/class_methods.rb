# frozen_string_literal: true

module StateMachines
  class Machine
    module ClassMethods
      # Attempts to find or create a state machine for the given class.  For
      # example,
      #
      #   StateMachines::Machine.find_or_create(Vehicle)
      #   StateMachines::Machine.find_or_create(Vehicle, :initial => :parked)
      #   StateMachines::Machine.find_or_create(Vehicle, :status)
      #   StateMachines::Machine.find_or_create(Vehicle, :status, :initial => :parked)
      #
      # If a machine of the given name already exists in one of the class's
      # superclasses, then a copy of that machine will be created and stored
      # in the new owner class (the original will remain unchanged).
      def find_or_create(owner_class, *args, &)
        options = args.last.is_a?(Hash) ? args.pop : {}
        name = args.first || :state

        # Find an existing machine
        machine = (owner_class.respond_to?(:state_machines) &&
                  ((args.first && owner_class.state_machines[name]) || (!args.first &&
                  owner_class.state_machines.values.first))) || nil

        if machine
          # Only create a new copy if changes are being made to the machine in
          # a subclass
          if machine.owner_class != owner_class && (options.any? || block_given?)
            machine = machine.clone
            machine.initial_state = options[:initial] if options.include?(:initial)
            machine.owner_class = owner_class
            # Configure async mode if requested in options
            if options.include?(:async)
              machine.configure_async_mode!(options[:async])
            end
          end

          # Evaluate DSL
          machine.instance_eval(&) if block_given?
        else
          # No existing machine: create a new one
          machine = new(owner_class, name, options, &)
        end

        machine
      end

      def draw(*)
        raise NotImplementedError
      end

      # Default messages to use for validation errors in ORM integrations
      # Thread-safe access via atomic operations on simple values
      attr_accessor :ignore_method_conflicts

      def default_messages
        @default_messages ||= {
          invalid: 'is invalid',
          invalid_event: 'cannot transition when %s',
          invalid_transition: 'cannot transition via "%1$s"'
        }.freeze
      end

      def default_messages=(messages)
        # Atomic replacement with frozen object
        @default_messages = deep_freeze_hash(messages)
      end

      def replace_messages(message_hash)
        # Atomic replacement: read current messages, merge with new ones, replace atomically
        current_messages = @default_messages || {}
        merged_messages = current_messages.merge(message_hash)
        @default_messages = deep_freeze_hash(merged_messages)
      end

      attr_writer :renderer

      def renderer
        return @renderer if @renderer

        STDIORenderer
      end

      private

      # Deep freezes a hash and all its string values for thread safety
      def deep_freeze_hash(hash)
        hash.each_with_object({}) do |(key, value), frozen_hash|
          frozen_key = key.respond_to?(:freeze) ? key.freeze : key
          frozen_value = value.respond_to?(:freeze) ? value.freeze : value
          frozen_hash[frozen_key] = frozen_value
        end.freeze
      end
    end
  end
end
