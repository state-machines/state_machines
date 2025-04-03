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
      def find_or_create(owner_class, *args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        name = args.first || :state

        # Find an existing machine
        machine = owner_class.respond_to?(:state_machines) &&
                  (args.first && owner_class.state_machines[name] || !args.first &&
                  owner_class.state_machines.values.first) || nil

        if machine
          # Only create a new copy if changes are being made to the machine in
          # a subclass
          if machine.owner_class != owner_class && (options.any? || block_given?)
            machine = machine.clone
            machine.initial_state = options[:initial] if options.include?(:initial)
            machine.owner_class = owner_class
          end

          # Evaluate DSL
          machine.instance_eval(&block) if block_given?
        else
          # No existing machine: create a new one
          machine = new(owner_class, name, options, &block)
        end

        machine
      end

      def draw(*)
        raise NotImplementedError
      end

      # Default messages to use for validation errors in ORM integrations
      attr_accessor :ignore_method_conflicts

      def default_messages
        @default_messages ||= {
          invalid: 'is invalid',
          invalid_event: 'cannot transition when %s',
          invalid_transition: 'cannot transition via "%1$s"'
        }
      end

      def default_messages=(messages)
        @default_messages = messages
      end

      def replace_messages(message_hash)
        message_hash.each do |key, value|
          default_messages[key] = value
        end
      end

      attr_writer :renderer

      def renderer
        return @renderer if @renderer

        STDIORenderer
      end
    end
  end
end
